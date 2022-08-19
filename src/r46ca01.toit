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
  static DEFAULT_UNIT_ID ::= 1
  static DEFAULT_BAUD_RATE ::= 9600

  static TEMPERATURE_ADDRESS_ ::= 0x00
  static UNIT_ID_ADDRESS_ ::= 0x02
  static BAUD_RATE_ADDRESS_ ::= 0x03
  static CORRECTION_ADDRESS_ ::= 0x04

  static BAUD_RATE_1200_ ::= 0
  static BAUD_RATE_2400_ ::= 1
  static BAUD_RATE_4800_ ::= 2
  static BAUD_RATE_9600_ ::= 3
  static BAUD_RATE_19200_ ::= 4

  registers_/modbus.HoldingRegisters

  /**
  Creates a new R46CA01 driver.

  The given Modbus $station must be a R46CA01 device.
  */
  constructor station/modbus.Station:
    registers_ = station.holding_registers

  /**
  Creates a new R46CA01 driver.

  Uses $detect_unit_id to find the unit id of the R46CA01 device.
  The R46CA01 device must be the only device on the bus.
  */
  constructor.detect bus/modbus.Modbus:
    id := detect_unit_id bus
    return R46ca01 (bus.station id)

  /**
  Reads the unit id (also known as "server address", or "station address") from the connected sensor.

  Note that only one unit must be on the bus when performing this action.
  */
  static detect_unit_id bus/modbus.Modbus -> int:
    broadcast_station := bus.station 0xFF
    return broadcast_station.holding_registers.read_single --address=UNIT_ID_ADDRESS_

  /**
  Reads the temperature.

  Returns the result in degrees Celsius.
  */
  read_temperature -> float:
    raw := read_temperature --raw
    if raw == 0x8000: throw "NO_DS18B20_OR_ERROR"
    return raw * 0.1

  /**
  Reads the temperature and returns the raw value.

  Returns the value as given by the sensor.
  If the returned value equals 0x8000 then no DS18B20 is connected to the
    board, or another error was encountered.

  Each unit corresponds to 0.1 degrees Celsius.
  */
  read_temperature --raw/bool -> int:
    if not raw: throw "INVALID_ARGUMENT"
    return read_ TEMPERATURE_ADDRESS_

  /**
  Reads the correction value.

  Returns the correction value in degrees Celsius.
  */
  read_correction -> float:
    return (read_correction --raw) * 0.1

  /**
  Reads the correction value.

  Returns the raw correction value as reported by the sensor. Each unit corresponds
    to 0.1 degrees Celsius.
  */
  read_correction --raw/bool -> int:
    if not raw: throw "INVALID_ARGUMENT"
    return read_ CORRECTION_ADDRESS_

  /**
  Sets the correction value.

  The reported temperature is adjusted by this value. A positive value
    increases the temperature, and a negative value decreases it.
  */
  set_correction value/float:
    set_correction --raw (value * 10).to_int

  /**
  Sets the correction value.

  Writes the given $value as raw value to the sensor.
  Each unit corresponds to 0.1 degrees Celsius. A positive value
    increases the temperature, and a negative value decreases it.
  */
  set_correction --raw value/int:
    if not raw: throw "INVALID_ARGUMENT"
    write_ --address=CORRECTION_ADDRESS_ value

  /**
  Changes the unit id (also known as "server address", or "station address") to the given $id.

  After this call, this current instance will be unable to communicate with the sensor (unless the chosen $id is the
    unit id that is already set). One has to create a new instance with the new station.

  The $id must be in range 1-247.
  */
  set_unit_id id/int:
    if not 1 <= id <= 247: throw "INVALID_ARGUMENT"
    write_ --address=UNIT_ID_ADDRESS_ id

  /**
  Sets the baud rate of the sensor.

  The change will only take effect after a reboot of the sensor.

  The $baud_rate must be one of:
  - 1200
  - 2400
  - 4800
  - 9600 (default)
  - 19200
  */
  set_baud_rate baud_rate/int:
    register_value /int := ?
    if baud_rate == 1200: register_value = BAUD_RATE_1200_
    else if baud_rate == 2400: register_value = BAUD_RATE_2400_
    else if baud_rate == 4800: register_value = BAUD_RATE_4800_
    else if baud_rate == 9600: register_value = BAUD_RATE_9600_
    else if baud_rate == 19200: register_value = BAUD_RATE_19200_
    else: throw "INVALID_ARGUMENT"
    write_ --address=BAUD_RATE_ADDRESS_ register_value

  read_ address/int -> int:
    // Note that the R46CA01 must use function 0x03 (read holding registers) and 0x06 (write single holding register).
    // Other functions are not officially supported.
    return registers_.read_int16 --address=address

  write_ --address/int value/int:
    registers_.write_single --address=address value
