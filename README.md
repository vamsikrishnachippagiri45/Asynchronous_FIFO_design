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

<img width="1141" height="623" alt="image" src="https://github.com/user-attachments/assets/7d17ee5f-875b-4cd8-86f0-26dbdc02cd0a" />
credits : vlsiverify.com
