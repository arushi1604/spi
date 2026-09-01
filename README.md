# Full-Duplex SPI Verification

This project verifies a configurable **SPI (Serial Peripheral Interface) master and slave** design in SystemVerilog, using a self-checking testbench written for **Icarus Verilog + GTKWave**. The design supports full-duplex transfer, 12-bit data words and all four standard SPI modes (CPOL/CPHA combinations).

## Project Highlights

- Full-duplex SPI communication over `MOSI` and `MISO`
- Parameterized data width (`DW`), default 12 bits
- Configurable SPI mode using `CPOL` and `CPHA`
- Verified across all four SPI modes, 5 random transactions each (20 total transfers)
- Self-checking testbench: compares received data against expected data automatically
- Simulated and verified using Icarus Verilog, waveforms viewed in GTKWave

| SPI Mode | CPOL | CPHA | Clock Idle | Sampling Edge | Shifting Edge |
|---|---:|---:|---|---|---|
| Mode 0 | 0 | 0 | Low | Rising | Falling |
| Mode 1 | 0 | 1 | Low | Falling | Rising |
| Mode 2 | 1 | 0 | High | Falling | Rising |
| Mode 3 | 1 | 1 | High | Rising | Falling |

## Repository Structure

```text
.
+-- design.sv              # SPI master, SPI slave, top-level wrapper (original design)
+-- tb_iverilog.sv         # Self-checking testbench (written for Icarus Verilog)
+-- README.md              # Project overview and quick-start guide
+-- result/           # Simulation and waveform screenshots
```

## Design Overview

The top-level design connects one SPI master to one SPI slave:

```text
master mosi ---> slave
master miso <--- slave
master sclk ---> slave
master cs   ---> slave
```

Both devices transmit and receive at the same time. During each transaction:

- `m_din` is shifted from the master to the slave and appears as `s_dout`.
- `s_din` is shifted from the slave to the master and appears as `m_dout`.
- `master_done` pulses when the master's transfer is complete.
- `slave_done` pulses when the slave has received a full word.

## Expected Verification Result

The testbench runs 5 random transactions for each of the 4 SPI modes, for a total of 20 full-duplex transfers. A passing run ends with:

```text
ALL 4 CPOL/CPHA COMBINATIONS COMPLETE
TOTAL TRANSACTIONS : 20
TOTAL ERROR COUNT  : 0
```

### Simulation Result

![Simulation Result](screenshots/simulation_result.png)

### Waveforms — All 4 SPI Modes

**Mode 0 (CPOL=0, CPHA=0)**
![Mode 0 Waveform](screenshots/mode_0.png)

**Mode 1 (CPOL=0, CPHA=1)**
![Mode 1 Waveform](screenshots/mode_1.png)

**Mode 2 (CPOL=1, CPHA=0)**
![Mode 2 Waveform](screenshots/mode_2.png)

**Mode 3 (CPOL=1, CPHA=1)**
![Mode 3 Waveform](screenshots/mode_3.png)

