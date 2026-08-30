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

## Why Gray Code is Required with 2-FF Synchronizers
A 2-FF synchronizer resolves metastability exclusively for single-bit signals. If standard binary counters are passed across domains:
* Multi-bit transitions occur simultaneously (e.g., binary `3` (`011`) transitioning to `4` (`100`) toggles 3 bits).
* Due to unavoidable layout routing skews, wire delays, and PVT variations, individual bits arrive at slightly different instants.
* The destination clock can sample an intermediate invalid state (such as `000`, `010`, or `111`), causing the FIFO to falsely flag a full or empty condition.

Gray code solves this by enforcing a unit-distance code property: **only 1 bit changes per increment** (e.g., Gray `3` (`010`) to Gray `4` (`110`) toggles only the MSB). If the destination clock samples mid-transition:
* It captures either the old pointer value (`010`) or the new pointer value (`110`).
* Both outcomes represent valid sequential states. An old pointer simply introduces a 1-cycle latency in flag deassertion (a safe, pessimistic condition) without ever corrupting the FIFO state.



## FIFO Full and Empty Flag Generation 

In an Asynchronous FIFO, status flags indicate buffer boundaries to prevent data overwrite (**overflow**) and reading invalid data (**underflow**). Because read and write operations execute on separate, unsynchronized clock domains, flag generation relies on cross-domain pointer comparisons using extended Gray-coded vectors.


### Pointer Width Extension

For a FIFO of depth $2^N$ :

* Memory locations require an $N$-bit address index ($0 \text{ to } 2^N - 1$).
* Pointers are deliberately sized to **$N + 1$ bits**.
* The lower $N$ bits select the active memory address, while the extra Most Significant Bit (MSB) acts as a **wrap-around / phase indicator**.
* This extra bit allows the logic to distinguish between an **empty** condition and a **full** condition, both of which map to the same base memory address.


### FIFO Empty Condition Logic

* **Clock Domain:** Evaluated purely within the **Read Clock Domain** (`read_clk`).
* **Operational Meaning:** The FIFO is empty when the read pointer catches up to the write pointer, meaning all data written into the buffer has been read out.
* **Mechanism:** The local Gray-coded read pointer is compared directly against the synchronized Gray-coded write pointer.
* **Logic Condition:** An exact bit-for-bit equality across all $N + 1$ bits:
  * Both the wrap bit (MSB) and the lower memory index bits are identical.
  * When `read_ptr_gray == write_ptr_gray_sync`, the `fifo_empty` flag asserts immediately.

### FIFO Full Condition Logic

* **Clock Domain:** Evaluated purely within the **Write Clock Domain** (`write_clk`).
* **Operational Meaning:** The FIFO is full when the write pointer writes through the entire buffer, wraps around, and catches up to the read pointer from behind.
* **Binary Behavior:** In a standard binary representation, "Full" occurs when the write pointer has wrapped once (MSB is inverted) while pointing to the exact same physical memory offset as the read pointer (all lower $N$ bits match).
* **Gray Code Transformation:** 
  Due to the mathematical property of the Binary-to-Gray conversion ($G = B \oplus [B \gg 1]$):
  1. Inverting the MSB of a binary vector inverts both the **MSB** and the **second MSB** ($N\text{-th}$ and $(N-1)\text{-th}$ bits) of its Gray code counterpart.
  2. The remaining lower bits ($N-2$ down to $0$) remain completely unchanged.
* **Logic Condition:** The `fifo_full` flag asserts when:
  * The **MSB** of the write pointer is the inverse of the synchronized read pointer's MSB.
  * The **second MSB** of the write pointer is the inverse of the synchronized read pointer's second MSB.
  * All remaining **Least Significant Bits (LSBs)** are identical between both pointers.

### Pessimistic Flag Behavior & Safety

Because pointer exchange relies on multi-stage synchronizers across clock domains, the synchronized pointer always lags the real-time pointer by 2 clock cycles:

* **Pessimistic Empty:** When data is written, the empty flag may remain asserted for 2 read clock cycles longer than strictly necessary. This prevents reading un-stabilized data and is fully safe against underflow.
* **Pessimistic Full:** When data is read, the full flag may remain asserted for 2 write clock cycles longer than strictly necessary. This temporarily throttles writes without corrupting previously stored data and is fully safe against overflow.

---

## Simulation & Verification 

The asynchronous FIFO testbench is designed to validate cross-clock domain data integrity, boundary flag assertions, and overflow/underflow protection under independent, asynchronous clock frequencies.
<img width="1920" height="1020" alt="Screenshot 2026-08-30 183903" src="https://github.com/user-attachments/assets/ca26a083-dd37-4b6b-b405-1b75a815f97b" />



### Testbench Setup & Parameters

* **Write Clock Domain (`write_clk`):** Configured with a period of **10 ns** ($f = 100\text{ MHz}$).
* **Read Clock Domain (`read_clk`):** Configured with a period of **16 ns** ($f = 62.5\text{ MHz}$).
* **FIFO Dimensions:** Configured with `DATA_SIZE = 8` (8-bit data width) and `ADDR_SIZE = 3` (FIFO Depth = $2^3 = 8$ words).


### Verification Phases & Waveform Analysis

#### Phase 1: Asynchronous Reset Initialization (0 ns – 30 ns)
* Active-low reset signals (`write_rst_n`, `read_rst_n`) are asserted low at time $t = 0\text{ ns}$.
* Both write and read pointer registers clear to zero.
* **Flag Status:** `fifo_empty` initializes to logic **1**, while `fifo_full` initializes to logic **0**.
* At $t = 30\text{ ns}$, reset is deasserted high synchronously with the clock domains to begin functional testing.


#### Phase 2: Sequential Burst Write & Empty Deassertion (30 ns – 110 ns)
* Data values `0` through `7` are driven sequentially onto `write_data` with `write_req` asserted on consecutive negative edges of `write_clk`.
* After the first write operation, the updated write pointer traverses the 2-FF synchronizer into the read domain.
* **Empty Flag Behavior:** After the 2-stage synchronizer latency, `fifo_empty` deasserts from `1` to `0` (observed at ~68 ns), indicating valid readable data exists in memory.



#### Phase 3: FIFO Full Assertion & Overflow Protection (110 ns – 150 ns)
* Upon writing the 8th word (index `7`), the FIFO reaches its maximum capacity of 8 words.
* The write pointer logic evaluates `fifo_full_val` and asserts `fifo_full = 1` at ~115 ns.
* **Overflow Protection Test:** At $t = 125\text{ ns}$, an illegal write attempt (`write_data = 8'hFF`) is applied while `fifo_full` is high. 
* Internal write-enable gating prevents `write_bin` from incrementing, protecting the stored data words (`0` to `7`) from being overwritten.


#### Phase 4: Sequential Read & Full Deassertion (150 ns – 280 ns)
* The read interface initiates continuous read cycles by asserting `read_req = 1` on negative edges of `read_clk`.
* Data is extracted in exact First-In, First-Out order: `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`.
* **Full Flag Deassertion:** Once reading commences, the updated read pointer is synchronized back into the write domain, clearing `fifo_full` back to `0` at ~205 ns.


#### Phase 5: FIFO Empty Assertion & Underflow Protection (280 ns – 341 ns)
* After reading word `7`, all 8 stored words have been consumed from the buffer.
* The read pointer matches the synchronized write pointer, causing `fifo_empty` to assert high (`1`) at ~285 ns.
* **Underflow Protection Test:** Subsequent read attempts while `fifo_empty = 1` are blocked by internal gating logic, preventing invalid reads and pointer corruption before simulation finishes at 341 ns.
