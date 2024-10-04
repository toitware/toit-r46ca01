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

  log.set-default (log.default.with-level log.INFO-LEVEL)
  pin-rx := gpio.Pin RX
  pin-tx := gpio.Pin TX
  pin-rts := gpio.Pin RTS

  rs485-bus := rs485.Rs485
      --rx=pin-rx
      --tx=pin-tx
      --rts=pin-rts
      --baud-rate=r46ca01.R46ca01.DEFAULT-BAUD-RATE
  bus := modbus.Modbus.rtu rs485-bus

  // Assume that the sensor is the only one on the bus.
  sensor := r46ca01.R46ca01.detect bus

  sensor.set-correction 0.0
  temperature := sensor.read-temperature
  expect-equals 0.0 sensor.read-correction
  expect-equals 0 (sensor.read-correction --raw)

  sensor.set-correction 20.0
  expect-equals 20.0 sensor.read-correction
  expect-equals 200 (sensor.read-correction --raw)
  changed-temperature := sensor.read-temperature
  // Allow for 0.5 degrees change in the short time.
  expect 19.5 < changed-temperature - temperature < 20.5

  sensor.set-correction -20.0
  expect-equals -20.0 sensor.read-correction
  expect-equals -200 (sensor.read-correction --raw)
  changed-temperature = sensor.read-temperature
  // Allow for 0.5 degrees change in the short time.
  expect -20.5 < changed-temperature - temperature < -19.5

  sensor.set-correction --raw 10
  expect-equals 1.0 sensor.read-correction
  expect-equals 10 (sensor.read-correction --raw)

  sensor.set-correction --raw -10
  expect-equals -1.0 sensor.read-correction
  expect-equals -10 (sensor.read-correction --raw)

  sensor.set-correction --raw 0

  old-id := r46ca01.R46ca01.detect-unit-id bus
  print "current unit id: $old-id"

  sensor.set-unit-id 5
  expect-equals 5 (r46ca01.R46ca01.detect-unit-id bus)
  sensor5 := r46ca01.R46ca01 (bus.station 5)
  expect (sensor5.read-temperature - temperature).abs < 0.5

  sensor5.set-unit-id 6
  expect-equals 6 (r46ca01.R46ca01.detect-unit-id bus)
  sensor6 := r46ca01.R46ca01 (bus.station 6)
  expect (sensor6.read-temperature - temperature).abs < 0.5

  print "Switching back to old unit id"
  sensor6.set-unit-id old-id

  if old-id != 5:
    expect-throw DEADLINE-EXCEEDED-ERROR: sensor5.read-temperature
  else:
    expect-throw DEADLINE-EXCEEDED-ERROR: sensor6.read-temperature

  print "done"
