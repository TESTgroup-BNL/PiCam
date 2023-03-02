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

## 2. PiCAM Assembly, Programming, and Operation Guidance
A step-by-step instruction on how to assemble a PiCAM can be found at: https://github.com/TESTgroup-BNL/PiCam/wiki/PiCAM-assembly. Note that the assemble needed 3-D printed cases for housing the parts inside a Flashlight case. The design of these 3-D printed cases can be found at: (Andrew, Jeremiah, please make sure that we include this in the package). This guidance also include detailed instructions on how to program a PiCAM after assembly, as well how to operate a PiCAM using externel cell phone or latlop devices.

## Other Resources:
Adafruit nRF platform wrapper: https://github.com/dmpolukhin/Adafruit_nRF52_Arduino/tree/master/cores/nRF5


## Point of Contact:
Shawn Serbin: sserbin@bnl.gov Andrew Mcmahon: amcmahon@bnl.gov Daryl Yang: dediyang@bnl.gov Jeremiah Anderson: jeanderson@bnl.gov
