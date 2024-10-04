// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
Tests changing of baudrate.

No connections except for the standard RS-485 connections are necessary.

Change the FROM_BAUDRATE and TO_BAUDRATE so that the sensor switches the setting.
Then reset the sensor, and change to the next pair.
After each execution the sensor must be reset (power-off).

Typically one would cycle through the available baud-rates:
- 1200
- 2400
- 4800
- 9600
- 19200
*/

import expect show *
import gpio
import r46ca01
import rs485
import modbus
import log

FROM-BAUD-RATE ::= 9600
TO-BAUD-RATE ::= 9600

RX ::= 17
TX ::= 16
RTS ::= 18

main:
  log.set-default (log.default.with-level log.INFO-LEVEL)

  from-baudrate := FROM-BAUD-RATE
  to-baudrate := TO-BAUD-RATE

  pin-rx := gpio.Pin RX
  pin-tx := gpio.Pin TX
  pin-rts := gpio.Pin RTS

  rs485-bus := rs485.Rs485
      --rx=pin-rx
      --tx=pin-tx
      --rts=pin-rts
      --baud-rate=from-baudrate
  bus := modbus.Modbus.rtu rs485-bus

  // Assume that the sensor is the only one on the bus.
  sensor := r46ca01.R46ca01.detect bus

  sensor.set-baud-rate to-baudrate
  print "done"
