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
  * Parameterized dual-port RAM array with a capacity of 2^ADDR_SIZE \times DATA_SIZE bits.
  * Performs synchronous write operations on the rising edge of `write_clk` when `write_req` is asserted and the FIFO is not full.
  * Provides asynchronous (combinational) read access driven directly by `read_addr`.
---


## Key design concepts 

## Clock Domain Crossing (CDC) & Metastability 

### The CDC Timing Challenge
In a synchronous system, all registers operate on a single clock or phase-aligned clocks, ensuring signals arrive within defined setup time ($t_{su}$) and hold time ($t_{h}$) windows. In an Asynchronous FIFO, the write domain (`write_clk`) and read domain (`read_clk`) run on independent oscillators with no fixed phase or frequency relationship. When transmitting control pointers between these domains, the data transition will inevitably collide with an active clock edge, causing timing violations.

###  Physical Mechanism of Metastability
A digital flip-flop relies on cross-coupled inverting feedback loops to latch a stable logic `0` or `1`. When input data transitions within the setup/hold aperture:
* The internal storage node is driven toward an intermediate voltage threshold ($V_{DD} / 2$).
* The cross-coupled inverters enter an unstable equilibrium state.
* The output neither resolves to `0` nor `1` immediately; it floats, oscillates, or exhibits a non-deterministic propagation delay ($t_{co} \gg t_{co,max}$).
* If downstream combinational logic samples this unresolved level, different logic gates may interpret the voltage differently, causing catastrophic logic corruption and illegal state transitions.

### MTBF (Mean Time Between Failures)
The statistical reliability of an asynchronous interface against metastability is quantified by the Mean Time Between Failures (MTBF) formula:

$$\text{MTBF} = \frac{e^{\frac{t_r}{\tau}}}{T_w \cdot f_{clk} \cdot f_{data}}$$

Where:
* $f_{clk}$ is the destination clock frequency.
* $f_{data}$ is the frequency of the transitioning asynchronous input signal.
* $T_w$ is the metastability vulnerability aperture (setup/hold violation window).
* $\tau$ (Tau) is the flip-flop resolution time constant (process/technology dependent).
* $t_r$ is the allocated settling time before downstream logic samples the value ($t_r \approx T_{clk} - t_{su}$).

Because $t_r$ appears in the exponent, increasing the available settling time exponentially improves the MTBF from fractions of a second to millions of operational years.

### Mitigation: The 2-Flip-Flop Synchronizer
To provide the required settling time ($t_r$), a 2-Flip-Flop (2-FF) synchronizer chain is placed at the domain boundary:
* **Stage 1 (Capture Flip-Flop):** Samples the raw asynchronous pointer. If a setup or hold violation occurs, this stage absorbs the metastable event.
* **Settling Window:** The output of Stage 1 is given a full clock period ($T_{clk}$) to decay to a deterministic logic `0` or `1`.
* **Stage 2 (Resolution Flip-Flop):** Samples the now-stabilized output of Stage 1, delivering a clean, glitch-free, synchronized signal to downstream logic.

### Why Gray Code is Required with 2-FF Synchronizers
A 2-FF synchronizer resolves metastability exclusively for single-bit signals. If standard binary counters are passed across domains:
* Multi-bit transitions occur simultaneously (e.g., binary `3` (`011`) transitioning to `4` (`100`) toggles 3 bits).
* Due to unavoidable layout routing skews, wire delays, and PVT variations, individual bits arrive at slightly different instants.
* The destination clock can sample an intermediate invalid state (such as `000`, `010`, or `111`), causing the FIFO to falsely flag a full or empty condition.

Gray code solves this by enforcing a unit-distance code property: **only 1 bit changes per increment** (e.g., Gray `3` (`010`) to Gray `4` (`110`) toggles only the MSB). If the destination clock samples mid-transition:
* It captures either the old pointer value (`010`) or the new pointer value (`110`).
* Both outcomes represent valid sequential states. An old pointer simply introduces a 1-cycle latency in flag deassertion (a safe, pessimistic condition) without ever corrupting the FIFO state.
