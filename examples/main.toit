// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
Demonstrates the use of the driver using a common uart-rs485 transceiver, such as the
  SP3485, used in the BOB-10124 transceiver breakout board.
*/

import gpio
import r46ca01
import rs485
import modbus

RX ::= 17
TX ::= 16
RTS ::= 18

main:
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

  print sensor.read-temperature
