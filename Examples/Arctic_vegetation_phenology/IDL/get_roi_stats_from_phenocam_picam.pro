pro get_roi_stats_from_phenocam_picam
;****************************************************************************
; this program is for extracting vegetation indices from time-series phenocam
; rgb images. along with vegetation indices, image collection time is also 
; extracted from exif file

; inputs:
; phenocamDIR: directory to a folder that contains time-series rgb images 
;              collected by a phenocam
; roiDIR:  directory to the roi file that contains one or more rois that 
;          stats need to be extracted. for each roi file, its tile must
;          include the start date and end date that vegetion stats should
;          be extracted for this roi. the roi fine need to be named in 
;          the format of  ***_YYYYMMDD_YYYYMMDD, where the firstYYYYMMDD 
;          is the start date, and second YYYYMMDD is the end date
; output:
; a csv file that contains image collection data and multiple vegetation
; indices
;*****************************************************************************
; recrod the time of start
startT=systime(1)
;**************************** user parameters ********************************
; define output directory 
outDIR = '' ; e.g., '\\modex.bnl.gov\data2\dyang\projects\ngee_arctic\seward\analysis\phenology\pheno_analysis\example_koug\gcc_ts'
; make a folder for the directory if it does exist
file_mkdir, outDIR

;; define the first date of image collection starts
;startDATE = julday(01,01,2017)
;; define the number of days of observation
;obsLEN = 365
;; generate the dates in julien to search for images
;dateJUL = timegen(obsLEN, START = startDATE)
;; covnert julien dates to world dates
;dateYMD = GenCalDates(dateJUL)

; define the format of your roi file
fm_roi = '' ; e.g., '.hdr'
;*****************************************************************************

;******************************* load data ***********************************
; define directory to phenocam time-series images
phenocamDIR = '' ; e.g., '\\modex.bnl.gov\data2\dyang\projects\ngee_arctic\seward\data\phenocam\picam\02_Data\Kougarok\PiCam_014'
rgbLIST = file_search(phenocamDIR, '*.JPG', /test_regular)

;;;;extract the name to match
filename = file_basename(phenocamDIR)
str_match = strmid(filename, 0, 6)

; define directory to roi (use imagery here)
roiDIR = '' ;e.g., '\\modex.bnl.gov\data2\dyang\projects\ngee_arctic\seward\analysis\phenology\pheno_analysis\example_koug'
; search all roi image files in roi folder
roiLIST = file_search(roiDIR, '*picam014*'+fm_roi, count=numROI, /test_regular)
;roiLIST = file_search(roiDIR, str_match+'*'+fm_roi, count=numROI, /test_regular)
;******************************* load data ***********************************

;***************************** main function *********************************
; extract roi stats for each roi file, one by one
foreach roi, roiLIST do begin
  ;;; extract date range of current roi from its name
  ; extract the roi filename
  roiname = file_basename(roi, fm_roi)
  ; extract collection start and end date for roi extraction
  dateSTART = strmid(roiname, 16, 8, /reverse_offset)
  dateSTART = julday(strmid(dateSTART, 4,2), strmid(dateSTART, 6,2), $
    strmid(dateSTART, 0,4))
  dateEnd= strmid(roiname, 7, 8, /reverse_offset)
  dateEnd = julday(strmid(dateEnd, 4,2), strmid(dateEnd, 6,2), $
    strmid(dateEnd, 0,4))
  ; generate a vector of dates that from the start to the end
  dateJUL = timegen(dateEnd-dateSTART+1, START = dateSTART)
  ; covnert julien dates to a vector that contain yeah, month, day
  dateYMD = dateconvert(dateJUL)

  ;;; extract roi stats for the current roi
  ; find phenocam images that match the time range of the roi
  rgbUSE = match(rgbLIST, dateYMD)
  
  ; calculate roi stats
  roiSTAT = roistats(roi, rgbUSE, outDIR, fm_roi)

endforeach

print, 'total time used:', floor((systime(1)-startT)/3600), 'h',$
  floor(((systime(1)-startT) mod 3600)/60), 'm',(systime(1)-startT) $
  mod 60,'s'
end

function dateconvert, JulianDATE
;****************************************************************************
; this function convert a vector of julian dates into a dataframe that 
; contains three conlumns - year, month, and day of the all dates in the
; input vector

; inputs:
; phenocamDIR: a vector of julian dates
; output:
; ymdDATE: a dataframe that contains three conlumns - year, month, and day of 
; the all dates in the  input vector
;****************************************************************************
numDATE = n_elements(JulianDATE)
ymdDATE = strarr(numDate)
for i=0, numDATE-1 do begin
  iDATE = JulianDATE[i]
  caldat, iDATE, month, day, year
  ymd = strtrim(year,1)+'-'+strtrim(month,1)+'-'+strtrim(day,1)
  ymdDATE[i] = ymd
endfor
; return the year month day dataframe
return,transpose(ymdDATE)
end


function gettimeinfo, rgbLIST
;****************************************************************************
; this function extracts the image collection date from exif file for a given
; jpg image list

; inputs:
; rgbLIS: a list of dirs for phenocam rgb files
; output:
; timeINFO: a dataframe that contains filename, orginal unformated time, and
; extract yyyymmdd and hhmmss for all images
;****************************************************************************
numRGB = n_elements(rgbLIST)
timeINFO = []
foreach rgb, rgbLIST do begin
  ; extract rgb collection data from exif file
  
  rgbNAME = file_basename(rgb, '.JPG')
  rgbTIME = strmid(rgbNAME, 16, 17, /REVERSE_OFFSET)
 
  ; extract yyyy-mm-dd and hh:mm:ss
  rgbYYYY = strmid(rgbTIME, 0,4)
  rgbMM = long(strmid(rgbTIME, 5,2))
  rgbDD = long(strmid(rgbTIME, 8,2))
  rgbYMD = rgbYYYY + '-' + strtrim(rgbMM, 1) + '-' + strtrim(rgbDD, 1)
  
  rgbHH = strmid(rgbTIME, 11, 2)
  rgbMM = strmid(rgbTIME, 13, 2)
  rgbSS = strmid(rgbTIME, 15, 2)
  rgbHMS = strtrim(rgbHH, 1) + ':' + strtrim(rgbMM, 1) + ':' + strtrim(rgbSS, 1)

  ; combine rgb file name, orginal time, extracted yyyy-mm-dd and hh:mm:ss
  ; for saving
  outINFO = [rgb, rgbTIME, rgbYMD, rgbHMS]
  
  ; save infor
  timeINFO = [[timeINFO],[outINFO]]
endforeach

return, timeINFO
end

function match, rgbLIST, dateLIST
;****************************************************************************
; this function searches all files in rgbLIST that are collected on the dates
; defined in dateLIST

; inputs:
; rgbLIS: a list of dirs for phenocam rgb files
; dateLIST: a vector file that contains the date to extract
; output:
; rgbuseinfo: a list taht includes all files in rgbLIST that are collected on 
; the dates defined in dateLIST
;****************************************************************************
; extract rgb date collection date and time info from exif file
rgbtimeinfo = gettimeinfo(rgbLIST)
matchtable = []
rgbuseinfo = []
; match rgb data collection info with given date list
foreach dateYMD, dateLIST do begin
  rowmatch = where(rgbtimeinfo[2, *] eq dateYMD, count)
  if count eq 0 then begin
    matchtable = [[matchtable], [dateYMD, 'NAN', 'NAN']]
  endif
  if count gt 0 then begin
    temp = transpose(replicate(dateYMD, count))
    matchtable = [[matchtable], [temp,rgbtimeinfo[2:3, rowmatch]]]
    ; save matched rgb list for use
    rgbuseinfo = [[rgbuseinfo], [rgbtimeinfo[0, rowmatch]]]
  endif
endforeach
return, rgbuseinfo
end

function roistats, roi, rgbLIST, outDIR, fm_roi
;****************************************************************************
; this function extracts rgb and vegetation stastics for each roi inside 
; the roi file

; inputs:
; roi: roi file that contains one more rois for the rgb to extract vegetation
; stats
; rgbLIST: a list of rgb files that correspond to the roi file
; dateLIST: a list of date that on which vegetation stats will be extracted
; output:
; ymdDATE: a dataframe of vegetation stats for the roi
;****************************************************************************
; open and load in roi file
roiRST = envi.openraster(roi)
roiIMG = roiRST.getdata()
; find out how many rois inside the roi file
roiIDs = roiIMG[uniq(roiIMG, sort(roiIMG))]
roiIDs = roiIDs[1:(n_elements(roiIDs)-1)]

; process roi one by one  
foreach roiID, roiIDs do begin
  ; get roi basename to save out in the table
  roiname = file_basename(roi, fm_roi)
  mask = fltarr(roiRST.nsample, roiRST.nrow) * !VALUES.F_NAN
  mask[where(roiIMG eq roiID)] = 1
  ; load in rgb image for calculating roi stats
  roiSTAT = []
  foreach rgb, rgbLIST do begin
    rgbRST = envi.openraster(rgb)
    rgbREFL=fltarr(rgbRST.nband)
    ; extract rgb collection date
    ;rgbEXIF = file_modtime(rgb)
    rgbTIME = gettimeinfo(rgb)
    for b=0, rgbRST.nband-1 do begin
      band = rgbRST.getdata(band = b)
      band = band * mask
      bandMEAN=mean(band[where(finite(band))])
      rgbREFL[b] = bandMEAN
    endfor
    ; calculate gcc
    gcc = rgbREFL[1]/total(rgbREFL)
    dataCOMBN = [string(rgbTIME[2]), string(rgbTIME[3]), strtrim(rgbREFL,0), strtrim(gcc,0)]
    ; get a camera info from roi file name

    roiSTAT = [[roiSTAT],[roiname,strtrim(fix(roiID),1),dataCOMBN]]
    rgbRST.close
  endforeach
  ; save roi stats for current roi
  outNAME = outDIR + '\' + roiname + '_roi'+strtrim(fix(roiID),1) + '.csv'
  write_csv,outNAME, roiSTAT, header = ['camera_id', 'roi_id', 'date', 'time', 'red', $
    'green', 'blue','gcc']
endforeach
end
