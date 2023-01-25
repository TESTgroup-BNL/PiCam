"wiring_analog.h" and "wiring_analog_nRF52.c" should go in the cores\nRF5 directory of the "Arduino Core for Adafruit Bluefruit nRF52 Boards" to support battery voltage reading.

Note that a fork of Adafruit package created by dmpolukhin is used for PCA10059 (nrf52840 Dongle) support.  This is configured in platformio.ini, noted here just for reference.

platform = https://github.com/dmpolukhin/platform-nordicnrf52.git
board = nordic_nrf52840_dongle
platform_packages = framework-arduinoadafruitnrf52@https://github.com/dmpolukhin/Adafruit_nRF52_Arduino.git