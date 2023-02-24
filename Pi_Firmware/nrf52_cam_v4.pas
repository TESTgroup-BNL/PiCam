program nrf52_cam_v4;

{$mode objfpc}{$H+}

uses
  RaspberryPi, {Include RaspberryPi to make sure all standard functions are included}
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  //BCM2835,
  //BCM2708,
  SysUtils,
  Serial,   {Include the Serial unit so we can open, read and write to the device}
  UltiboUtils,  {Include Ultibo utils for some command line manipulation}
  Syscalls,     {Include the Syscalls unit to provide C library support}
  VC4,          {Include the VC4 unit to enable access to the GPU}

  Classes,     {Include the common classes}
  FileSystem,  {Include the file system core and interfaces}
  FATFS,       {Include the FAT file system driver}
  MMC,         {Include the MMC/SD core to access our SD card}
  BCM2708,     {And also include the MMC/SD driver for the Raspberry Pi}
  base64;

var
 Count:LongWord;
 Characters:String;
 fname:String;
 fsize:Int64;
 argc:int;      {Some command line arguments to pass to the C code}
 argv:PPChar;
 Filename: String;
 ConfigFN: String;
 Logfile: Textfile;
 Configfile: Textfile;
 ConfigStr: String;
 vBatt:String;
 i:int;
 preview:boolean;

 img_buf:string;

 //buf_size:LongWord;
 //buffer:Pointer;
 //FileStream:TFileStream;

{Link our C library to include the original example}
{$linklib raspistill}

{Import the main function of the example so we can call it from Ultibo}
function vcraspistill(argc: int; argv: PPChar): int; cdecl; external 'raspistill' name 'vcraspistill';

const
  NL = Chr(13) + Chr(10);

procedure serStr(str: String);
var
 Characters:String;
 Count:LongWord;
begin
 Count:=0;
 //Characters:=FormatDateTime('hh:nn:ss',Now) + ': ' + str + NL;
 Characters:=str + NL;
 SerialWrite(PChar(Characters),Length(Characters),Count);
end;

function getSer(): String;
var
 Characters:String;
 Character:Char;
 Count:LongWord;

begin
 Count:=0;
 while True do
    begin
     SerialRead(@Character,SizeOf(Character),Count);
     if Character = #13 then
       begin
         getSer:=Characters;
         Break;
       end
     else if Character = #10 then
       begin
         //Ignore newline
       end
     else
       begin
        Characters:=Characters + Character;
       end;
    end;
end;



procedure copyfile2(src,dest:string);

var
 fh1,fh2,il:integer;
 buf:Pbyte;

begin
  buf:=Pbyte($3000000);
  fh1:=fileopen(src,$40);
  fh2:=filecreate(dest);
  il:=fileread(fh1,buf^,16000000);
  filewrite(fh2,buf^,il);
  fileclose(fh1);
  fileclose(fh2);
end;


function FileToBase64(const AFile: String; var Base64: String): Boolean;
var
  MS: TMemoryStream;
  Str: String;
begin
  Result := False;
  if not FileExists(AFile) then
    Exit;
  MS := TMemoryStream.Create;
  try
    MS.LoadFromFile(AFile);
    if MS.Size > 0 then
    begin
      SetLength(Str, MS.Size div SizeOf(Char));
      MS.ReadBuffer(Str[1], MS.Size div SizeOf(Char));
      Base64 := EncodeStringBase64(Str);
      Result := True;
    end;
  finally
    MS.Free;
  end;
end;

function GetFileSize(const Filename: string): int64;
var F : file of byte;
begin
  assign (F, Filename);
  reset (F);
  GetFileSize := System.FileSize(F);
  close (F);
end;

begin
  Filename:='C:\log.txt';
  ConfigFN:='C:\cam_cfg.txt';
 //AssignFile(Logfile, Filename );
 //Rewrite(Logfile);
 //writeln(Logfile, 'Date,Time,Temp1,Temp2,Temp3,Temp4');
 //Close(Logfile);

 if SerialOpen(230400,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0) = ERROR_SUCCESS then
  begin
   {Setup our starting point}
   Count:=0;
   Characters:='';

   //serStr('TEST PiCam' + NL + 'Waiting for drive C:\');

   while not DirectoryExists('C:\') do
    begin
     {Sleep for a second}
     Sleep(100);
    end;

   If Not DirectoryExists('C:\images\') then
    CreateDir ('C:\images\');

   AssignFile(Logfile,Filename);

   If Not FileExists(Filename) then
    Rewrite(Logfile)
   Else
    Append(Logfile);

   //serStr('Loading MMAL' + NL + 'Waiting for filename');

   //Get image directory index (prevents overwriting after power cycles if the date/time isn't set
   i:=0;
   while DirectoryExists('C:\images\'+IntToStr(i)+'\') do
    begin
     i:=i+1;
    end;
   i:=i-1;

   serStr(' fv?');  //added space because first char is sometimes corrupted
   fname:=getSer();

   //if (fname = '*p') then  //Preview Mode
   // begin
   //  //Change to raspbian, overwrite kernel.img
   //  DeleteFile('C:\config.txt');
   //  copyfile2('C:\config_r.txt','C:\config.txt');
   //  SystemRestart(0);
   // end;


   if (LeftStr(fname,2) = '*n') then  //New run
    begin
     i:=i+1;
     fname:=RightStr(fname, Length(fname) - 2);

     //Check for config
     if FileExists(ConfigFN) then
      begin
        Sleep(100);  //Give nrf52 a chance to catch its breath
        AssignFile(ConfigFile,ConfigFN);
        Reset(ConfigFile);
        while not Eof(ConfigFile) do
          begin
            Sleep(10);
            ReadLn(ConfigFile, ConfigStr);
            serStr(ConfigStr);
            getSer();         //Wait for next line request
          end;
        CloseFile(ConfigFile);
      end;
     serStr('!n');   //Let nrf52 know we're done with config
    end;

    if (LeftStr(fname,2) = '*p') then  //Send preview
      preview:=true
    else
      preview:=false;

   If Not DirectoryExists('C:\images\'+IntToStr(i)+'\') then
    CreateDir ('C:\images\'+IntToStr(i)+'\');

   if (preview = true) then
    begin
     //buffer:=GetMem(102400);  //Max 100kB
     Count:=0;
     vBatt:='preview';
     //buf_size:=0;

     fname:=RightStr(fname, Length(fname) - 2);
     argv:=AllocateCommandLine('--output C:\images\'+IntToStr(i)+'\prv_'+fname+'.jpg --timeout 1000 -rot 180 -w 320 -h 240 -q 25',argc);
     vcraspistill(argc, argv);
     ReleaseCommandLine(argv);

     //FileStream:=TFileStream.Create('C:\images\'+IntToStr(i)+'\prv_'+fname+'.jpg',fmOpenRead or fmShareDenyNone);
     //buf_size:=FileStream.Read(buffer^,FileStream.Size);
     //FileStream.Free;

     FileToBase64('C:\images\'+IntToStr(i)+'\prv_'+fname+'.jpg',img_buf);

     writeln(Logfile, FormatDateTime('hh:nn:ss',Now) + ', '+IntToStr(i)+'\prv_'+fname+'.jpg, ' +  IntToStr(Round((Length(img_buf)+23)/1024)) + ', ' + vBatt);
     CloseFile(LogFile);  //Close the file before telling the nrf52 that we're done

     serStr('p! ' + IntToStr(Length(img_buf)+23));

     sleep(100); //Give nrf52 time to allocate buffer and send feedback strings

     SerialWrite(PChar('*data:image/jpeg;base64,' + img_buf),Length(img_buf)+23,Count);
    end
   else
     begin
       vBatt:=getSer();

       //serStr('Received filename: ' + fname);

       MMALIncludeComponentVideocore;

       //serStr('Taking image');

       argv:=AllocateCommandLine('--output C:\images\'+IntToStr(i)+'\img_'+fname+'.jpg --timeout 1000 -rot 180',argc);

       vcraspistill(argc, argv);

       //serStr('Done, releasing command line...');
       ReleaseCommandLine(argv);

       fsize:=GetFileSize('C:\images\'+IntToStr(i)+'\img_'+fname+'.jpg');

       writeln(Logfile, FormatDateTime('hh:nn:ss',Now) + ', '+IntToStr(i)+'\img_'+fname+'.jpg, ' +  IntToStr(Round(fsize/1024)) + ', ' + vBatt);
       CloseFile(LogFile);  //Close the file before telling the nrf52 that we're done

       serStr('s! ' + IntToStr(Round(fsize/1024)) + ',' + FloatToStrF(diskFree(0)/(1024*1024*1024),ffFixed,2,2) + ',' + FloatToStrF(diskSize(0)/(1024*1024*1024),ffFixed,2,2) + ',' + IntToStr(i));
     end;

    Sleep(1000);
    SerialClose();
  end;
 {Halt the main thread here}
 ThreadHalt(0);
end.



