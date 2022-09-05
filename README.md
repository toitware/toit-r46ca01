# R46CA01

Driver for the R46CA01 temperature sensor.

The R46CA01 sensor is a module that combines a DS18B20 temperature probe with
an RS485 interface. It is manufactured by [eletechsup](https://www.ebay.com/str/eletechsupsofficialstore).

## Wiring
There are 6 variants of the R46CA01 sensor:
- R46CA01_ANO: VIN=3.7-5.5V, TTL232. The DS18B20 is *not* installed.
- R46CA01_ATS: VIN=3.7-5.5V, TTL232.
- R46CA01_BNO: VIN=3.7-5.5V, RS485. The DS18B20 is *not* installed.
- R46CA01_BTS: VIN=3.7-5.5V, RS485.
- R46CA01_CNO: VIN=6-25V, RS485. The DS18B20 is *not* installed.
- R46CA01_CTS: VIN=6-25V, RS485.

The C variants can be easily recognized as they have a voltage converter on the back.

## Standard configuration
The R46CA01's UART is configured for 9600, N, 8, 1. The speed can be configured via software.
