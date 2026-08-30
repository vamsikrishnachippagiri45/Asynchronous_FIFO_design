# Asynchronous_FIFO_design
This project demonstrates the design of an asynchronous FIFO for reliable data transfer between independent clock domains.


Overview

This project implements an Asynchronous FIFO (First-In First-Out) in Verilog HDL.

An asynchronous FIFO is used to transfer data safely between two different clock domains. The write operation is controlled by a write clock, while the read operation is controlled by an independent read clock.

The FIFO uses:

Independent write and read clocks
Binary write and read pointers
Gray-code pointers for clock-domain crossing
Two-flip-flop synchronizers
Full and empty detection
Dual-port FIFO memory

