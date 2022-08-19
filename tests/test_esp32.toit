// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
Tests the R46CA01 driver.
*/

import expect show *
import gpio
import r46ca01
import rs485
import modbus
import log

RX ::= 17
TX ::= 16
RTS ::= 18

main:
  print "starting"

  log.set_default (log.default.with_level log.INFO_LEVEL)
  pin_rx := gpio.Pin RX
  pin_tx := gpio.Pin TX
  pin_rts := gpio.Pin RTS

  rs485_bus := rs485.Rs485
      --rx=pin_rx
      --tx=pin_tx
      --rts=pin_rts
      --baud_rate=r46ca01.R46ca01.DEFAULT_BAUD_RATE
  bus := modbus.Modbus.rtu rs485_bus --baud_rate=r46ca01.R46ca01.DEFAULT_BAUD_RATE

  // Assume that the sensor is the only one on the bus.
  sensor := r46ca01.R46ca01.detect bus

  sensor.set_correction 0.0
  temperature := sensor.read_temperature
  expect_equals 0.0 sensor.read_correction
  expect_equals 0 (sensor.read_correction --raw)

  sensor.set_correction 20.0
  expect_equals 20.0 sensor.read_correction
  expect_equals 200 (sensor.read_correction --raw)
  changed_temperature := sensor.read_temperature
  // Allow for 0.5 degrees change in the short time.
  expect 19.5 < changed_temperature - temperature < 20.5

  sensor.set_correction -20.0
  expect_equals -20.0 sensor.read_correction
  expect_equals -200 (sensor.read_correction --raw)
  changed_temperature = sensor.read_temperature
  // Allow for 0.5 degrees change in the short time.
  expect -20.5 < changed_temperature - temperature < -19.5

  sensor.set_correction --raw 10
  expect_equals 1.0 sensor.read_correction
  expect_equals 10 (sensor.read_correction --raw)

  sensor.set_correction --raw -10
  expect_equals -1.0 sensor.read_correction
  expect_equals -10 (sensor.read_correction --raw)

  print "done"
