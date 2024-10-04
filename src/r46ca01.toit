// Copyright (C) 2022 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import modbus
import modbus.rs485 as modbus
import rs485
import gpio

/**
A driver for the R46CA01 temperature sensor.
*/
class R46ca01:
  static DEFAULT-UNIT-ID ::= 1
  static DEFAULT-BAUD-RATE ::= 9600

  static TEMPERATURE-ADDRESS_ ::= 0x00
  static UNIT-ID-ADDRESS_ ::= 0x02
  static BAUD-RATE-ADDRESS_ ::= 0x03
  static CORRECTION-ADDRESS_ ::= 0x04

  static BAUD-RATE-1200_ ::= 0
  static BAUD-RATE-2400_ ::= 1
  static BAUD-RATE-4800_ ::= 2
  static BAUD-RATE-9600_ ::= 3
  static BAUD-RATE-19200_ ::= 4

  registers_/modbus.HoldingRegisters

  /**
  Creates a new R46CA01 driver.

  The given Modbus $station must be an R46CA01 device.
  */
  constructor station/modbus.Station:
    registers_ = station.holding-registers

  /**
  Creates a new R46CA01 driver.

  Uses $detect-unit-id to find the unit id of the R46CA01 device.
  The R46CA01 device must be the only device on the bus.
  */
  constructor.detect bus/modbus.Modbus:
    id := detect-unit-id bus
    return R46ca01 (bus.station id)

  /**
  Reads the unit id (also known as "server address", or "station address") from the connected sensor.

  Note that only one unit must be on the bus when performing this action.
  */
  static detect-unit-id bus/modbus.Modbus -> int:
    broadcast-station := bus.station 0xFF
    return broadcast-station.holding-registers.read-single --address=UNIT-ID-ADDRESS_

  /**
  Reads the temperature.

  Returns the result in degrees Celsius.
  */
  read-temperature -> float:
    raw := read-temperature --raw
    if raw == 0x8000: throw "NO_DS18B20_OR_ERROR"
    return raw * 0.1

  /**
  Reads the temperature and returns the raw value.

  Returns the value as given by the sensor.
  If the returned value equals 0x8000 then no DS18B20 is connected to the
    board, or another error was encountered.

  Each unit corresponds to 0.1 degrees Celsius.
  */
  read-temperature --raw/bool -> int:
    if not raw: throw "INVALID_ARGUMENT"
    return read_ TEMPERATURE-ADDRESS_

  /**
  Reads the correction value.

  Returns the correction value in degrees Celsius.
  */
  read-correction -> float:
    return (read-correction --raw) * 0.1

  /**
  Reads the correction value.

  Returns the raw correction value as reported by the sensor. Each unit corresponds
    to 0.1 degrees Celsius.
  */
  read-correction --raw/bool -> int:
    if not raw: throw "INVALID_ARGUMENT"
    return read_ CORRECTION-ADDRESS_

  /**
  Sets the correction value.

  The reported temperature is adjusted by this value. A positive value
    increases the temperature, and a negative value decreases it.

  The correction is stored in non-volatile memory.
  */
  set-correction value/float:
    set-correction --raw (value * 10).to-int

  /**
  Sets the correction value.

  Writes the given $value as raw value to the sensor.
  Each unit corresponds to 0.1 degrees Celsius. A positive value
    increases the reported temperature, and a negative value decreases it.

  The correction is stored in non-volatile memory.
  */
  set-correction --raw value/int:
    if not raw: throw "INVALID_ARGUMENT"
    write_ --address=CORRECTION-ADDRESS_ value

  /**
  Changes the unit id (also known as "server address", or "station address") to the given $id.

  After this call, this current instance will be unable to communicate with the sensor (unless the chosen $id is the
    unit id that is already set). One has to create a new instance with the new station.

  The $id must be in range 1-247.
  */
  set-unit-id id/int:
    if not 1 <= id <= 247: throw "INVALID_ARGUMENT"
    write_ --address=UNIT-ID-ADDRESS_ id

  /**
  Sets the baud rate of the sensor.

  The change will only take effect after a reboot of the sensor.

  The $baud-rate must be one of:
  - 1200
  - 2400
  - 4800
  - 9600 (default)
  - 19200
  */
  set-baud-rate baud-rate/int:
    register-value /int := ?
    if baud-rate == 1200: register-value = BAUD-RATE-1200_
    else if baud-rate == 2400: register-value = BAUD-RATE-2400_
    else if baud-rate == 4800: register-value = BAUD-RATE-4800_
    else if baud-rate == 9600: register-value = BAUD-RATE-9600_
    else if baud-rate == 19200: register-value = BAUD-RATE-19200_
    else: throw "INVALID_ARGUMENT"
    write_ --address=BAUD-RATE-ADDRESS_ register-value

  read_ address/int -> int:
    // Note that the R46CA01 must use function 0x03 (read holding registers) and 0x06 (write single holding register).
    // Other functions are not officially supported.
    return registers_.read-int16 --address=address

  write_ --address/int value/int:
    registers_.write-single --address=address value
