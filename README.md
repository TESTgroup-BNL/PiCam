## Backgound
PiCAM is a custom-grade phenocam system designed by the [Terrestrial Ecosystem Science & Technology group](https://www.bnl.gov/envsci/testgroup/) at Brookhaven National Laboratory. The PiCAM has the advantage of being compact, low power cost, and lightweight, particularly suitable for Arctic environments. It was desinged to operate for at least a fiscal year (6 images per day) with three AA lithium batteries. Given its compact and light-weight feature, PiCAM can be deployed on small hosts (e.g., stakes), addressing the challenges of deploying heavy infrastructure commonly needed for commercial phenocams.

#### Below, we describe the parts, assemble, and basic operation of PiCAMs. Please also refer to XXX for more detailed technical description of the PiCAM and example applications in Arctic field sites. 

## 1. Parts for PiCAM
#### 2.1. Sensor Suite
* Camera (Raspberry Pi Camera v2; Raspberry Pi Foundation). Example source: https://www.raspberrypi.com/products/camera-module-v2/
* Camera cable (FFC Ribbon Cable; Generic). Example source: https://www.amazon.com/dp/B0716TB6X3/ref=twister_B08NTCX71W?_encoding=UTF8&psc=1
* GPS module (MINI GPS PA1010D STEMMA QT; Adafruit). Example source: https://www.digikey.com/en/products/detail/adafruit-industries-llc/4415/10709724
* GPS cable (FLEXIBLE QWIIC CABLE - 500MM; Sparkfun). Example source: https://www.digikey.com/en/products/detail/sparkfun-electronics/PRT-17257/13629026
#### 2.2. Central Control
* Supervisory controller (nrf52840; Nordic). Example source: https://www.digikey.com/en/products/detail/nordic-semiconductor-asa/NRF52840-DONGLE/9491124
* Camera controller (Raspberry Pi Zero; Raspberry Pi Foundation). Example source: https://www.raspberrypi.com/products/raspberry-pi-zero/
* Power Switch/Driver (TPS2080DR; Texas Instruments). Example source: https://www.digikey.com/en/products/detail/texas-instruments/TPS2080DR/1670863?s=N4IgTCBcDa4JwDYC0BmOKCsyCMSByAIiALoC%2BQA
#### 2.3. Power Supply
* Lithium Iron AA (Energizer; Part number: L91). Example source: https://www.energizer.com/batteries/energizer-ultimate-lithium-batteries
#### 2.4. Other Accessories
* Case (Flashlight; Fulton Industries). Example source: https://www.armynavysales.com/angle-head-flashlight-mx-991-u-me124-558.html
* Memory card (32GB Micro SD Card; Samsung). Users can choose the size depend on need
* SOIC-8 to DIP Breakout (BOB-13655; Sparkfun). Example source: https://www.digikey.com/en/products/detail/sparkfun-electronics/BOB-13655/5528943?s=N4IgTCBcDaIIwFYBsAOAtHOYDMaByAIiALoC%2BQA
* SWD Connector (10-pin 0.5mm; Samtec Inc.). Example source: https://www.digikey.com/en/products/detail/samtec-inc/SHF-105-01-F-D-SM/8410395

## 2. PiCAM Assembly Guidance
A step-by-step instruction on how to assemble a PiCAM can be found at: https://github.com/TESTgroup-BNL/PiCam/wiki/PiCAM-assembly. Note that the assemble needed 3-D printed cases for housing the parts inside a Flashlight case. The design of these 3-D printed cases can be found at: (Andrew, Jeremiah, please make sure that we include this in the package)

## 3. PiCAM Programming
# Andrew please help!!!

## 4. Communication with external devices
#### 4.1. The Advertising String
Visible without connecting or any specific software.  Anything (phone, computer, etc.) that can scan for Bluetooth devices should be able to “see” it.
Format: PiCam <ID> <Battery Level as %> <images captured in current run> <date> <time>

#### 4.2. Serial UART Connection
Provides a terminal-like text interface.  The Adafruit Bluefruit Connect app works great for this and is available for Android and iOS.
Usage: Once connected, the app will receive periodic strings from the camera with basic status information.  Sending any character will print out a menu with several options:
'c': Print cfg
'g': Get GPS fix
'i': Capture img now
'r': Reload cfg
't [YYYY,MM,DD,hh,mm,ss]': Set time

Sending the specified character will trigger the command.  Before entering the menu, sending a double character of any command will execute it without displaying the menu.  For example, to quickly trigger getting a GPS fix, sending ‘gg’ will immediately start that command.

#### 4.3. Web Dashboard
The web dashboard provides the most remote functionality including all the items from the UART menu as well as getting preview images and syncing time to the host.  It displays the UART data as a text feed and additionally parsing it to better display the data.
The dashboard utilizes Web Bluetooth, which is currently an experimental API but has reasonable support Chrome (the progress of adoption can be checked here).  Nevertheless, some bugs and changes should be expected as this continues to develop.  The current site being used for testing is hosted at https://web-picam.glitch.me/, but should be cached offline for use in the field.  Tip: Connecting can take 10-15 seconds; if the Bluetooth icon hasn’t appeared on the tab yet, clicking connect again sometimes does the trick.  Other times it causes a disconnect or a “double connection” where everything is printed twice (though commands still work fine). 
  
Preview image: When triggered, this powers up the Pi, captures a low resolution image and transfers it to the nrf52840, which finally transfers it to the dashboard.  Transferring from the Pi to the nrf52840 can be very slow (it’s 230400 baud serial), so it may take 15-30 seconds even for a small image.  The Bluetooth transfer is generally much faster, taking only a few seconds.  Chrome can be picky about rendering the image once it’s received; if it isn’t displayed immediately, try opening/switching to a different tab and then back to force it to redraw.

###### Important:  While connected to Bluetooth (UART or dashboard), the camera is consuming about 10 times as much power as in “normal” standby, so it is important to not stay connected indefinitely and to remember to disconnect!  (If a connection is dropped by device moving out a of range or interference, the camera will automatically drop the connection rather than being stuck in connected mode.)
![image](https://user-images.githubusercontent.com/41143480/220488276-373023ed-733e-4ed0-a034-7da8dce490a3.png)


## Point of Contact:
Shawn Serbin: sserbin@bnl.gov Andrew Mcmahon: amcmahon@bnl.gov Daryl Yang: dediyang@bnl.gov Jeremiah Anderson: jeanderson@bnl.gov
