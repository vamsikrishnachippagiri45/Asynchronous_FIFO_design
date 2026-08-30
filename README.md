# Asynchronous FIFO Design (CDC Safe)

A parameterized dual-clock Asynchronous FIFO (First-In, First-Out) buffer implemented in Verilog HDL. This design safely transfers data across asynchronous Clock Domains (CDC) using Gray code pointer conversion and 2-Flip-Flop (2-FF) synchronizers.

---

## Table of Contents
- [Overview](#overview)
- [Architecture & Block Diagram](#architecture--block-diagram)
- [Key Design Concepts](#key-design-concepts)
  - [Clock Domain Crossing (CDC) & Metastability](#1-clock-domain-crossing-cdc--metastability)
  - [Gray Code Encoding](#2-gray-code-encoding)
  - [Full and Empty Generation](#3-full-and-empty-condition-logic)
- [Module Breakdown](#module-breakdown)
- [Simulation & Verification](#simulation--verification)
- [Conclusion](#conclusion)

---

## Overview

In digital systems, transmitting data between sub-blocks operating on independent, unsynchronized clocks causes timing violations (setup and hold) that lead to metastability. This Asynchronous FIFO provides a robust bridge between differing read (`read_clk`) and write (`write_clk`) clock domains.

### Key Features
* **Independent Clock Domains:** Completely decoupled read and write operations.
* **Metastability Mitigation:** 2-FF synchronizer chain for safe cross-domain pointer propagation.
* **Multi-Bit Glitch Prevention:** Gray-coded read and write pointers ensure single-bit transitions per increment.
* **Parameterized:** Configurable word width and FIFO depth.

---
## Architecture & Block Diagram

<img width="1141" height="623" alt="image" src="https://github.com/user-attachments/assets/7d17ee5f-875b-4cd8-86f0-26dbdc02cd0a" />
credits : vlsiverify.com


### Key Architectural Blocks

* **`write_ptr_full` (Write Clock Domain):**
  * Maintains an internal binary counter (`ADDR_SIZE + 1` bits) to track write location and wrap-around state.
  * Drives the memory write address (`write_addr`) using the lower `ADDR_SIZE` bits.
  * Converts the binary counter value to Gray code (`write_ptr_gray`).
  * Compares `write_ptr_gray` with the synchronized read pointer (`read_ptr_gray_sync`) to generate `fifo_full`. Writes are blocked when `fifo_full` is asserted.

* **`read_ptr_empty` (Read Clock Domain):**
  * Maintains an internal binary counter (`ADDR_SIZE + 1` bits) to track read location.
  * Drives the memory read address (`read_addr`) using the lower `ADDR_SIZE` bits.
  * Converts the binary counter value to Gray code (`read_ptr_gray`).
  * Compares `read_ptr_gray` with the synchronized write pointer (`write_ptr_gray_sync`) to generate `fifo_empty`. Reads are blocked when `fifo_empty` is asserted.

* **Dual-Stage Synchronizers (`two_ff_sync`):**
  * **Read-to-Write Synchronizer:** Samples `read_ptr_gray` using `write_clk` across two cascaded D-flip-flops to produce `read_ptr_gray_sync`, mitigating metastability in the write domain.
  * **Write-to-Read Synchronizer:** Samples `write_ptr_gray` using `read_clk` across two cascaded D-flip-flops to produce `write_ptr_gray_sync`, mitigating metastability in the read domain.

* **`fifo_memory` (Storage Core):**
  * Parameterized dual-port RAM array with a capacity of $2^{\text{ADDR\_SIZE}} \times \text{DATA\_SIZE}$ bits.
  * Performs synchronous write operations on the rising edge of `write_clk` when `write_req` is asserted and the FIFO is not full.
  * Provides asynchronous (combinational) read access driven directly by `read_addr`.

---

### Signal Dataflow Summary

| Signal | Source Domain | Destination Domain | Purpose |
| :--- | :--- | :--- | :--- |
| `write_ptr_gray` | `write_clk` | `read_clk` (via 2-FF Sync) | Conveys write progress to read domain to evaluate `fifo_empty`. |
| `read_ptr_gray` | `read_clk` | `write_clk` (via 2-FF Sync) | Conveys read progress to write domain to evaluate `fifo_full`. |
| `write_addr` | `write_clk` | `fifo_memory` | Memory write address bus ($0 \text{ to } 2^{\text{ADDR\_SIZE}}-1$). |
| `read_addr` | `read_clk` | `fifo_memory` | Memory read address bus ($0 \text{ to } 2^{\text{ADDR\_SIZE}}-1$). |
