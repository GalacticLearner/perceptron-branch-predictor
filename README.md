# Perceptron Branch Predictor on a Pipelined CPU

This project extends a baseline 5-stage pipelined CPU by integrating a **Perceptron-Based Branch Predictor (PBP)**.

The goal of this work is **not to improve performance**, but to experimentally demonstrate the **hardware and computational overhead** introduced by advanced branch prediction techniques.

---

## 📌 Project Objective

Modern branch predictors (like perceptrons) are theoretically powerful, but they come with:

- Increased hardware complexity
- Additional arithmetic computation
- Potential increase in pipeline latency

### This project demonstrates:

> ⚠️ A perceptron branch predictor can significantly **increase execution cycles (~10x)** in a simple pipelined CPU due to computational overhead.

---

## 🧠 Background

The baseline CPU uses a simple 5-stage pipeline:

- IF (Instruction Fetch)
- ID (Instruction Decode)
- EX (Execute)
- MEM (Memory Access)
- WB (Write Back)

We extend this by adding:

- Global History Register (GHR)
- Perceptron weight table
- Dot-product based prediction logic
- Online training mechanism

---

## 🏗️ Project Structure

### 🔹 Baseline CPU (Unmodified)
- `cpu.v` – Core pipelined CPU
- `ALU.v` – Arithmetic Logic Unit
- `opcodes.v` – Instruction definitions

### 🔹 Added / Modified Components
- `PerceptronBranchPredictor.v` – Perceptron predictor implementation
- `GlobalHistoryRegister.v` – Stores branch history
- `PerceptronPredictionUnit.v` – Integration wrapper
- Modified `cpu.v` – Connected predictor to pipeline

### 🔹 Testbench
- `cpu_TB.v` – Simulation testbench
- `Memory.v` – Instruction/data memory
- `testbench.asm` – Benchmark program

### 🔹 Outputs
- `output.vcd` – Waveform dump
- Compiled executable (generated via Icarus Verilog)

---

## ⚙️ How the Perceptron Predictor Works

Each branch is predicted using:

```
y = w0 + w1*x1 + w2*x2 + ... + wn*xn
```

- `x` → branch history bits
- `w` → learned weights

**Prediction:**
- `y >= 0` → Taken
- `y < 0` → Not Taken

**Training:**
- Weights updated after branch resolves
- Update triggered on:
  - Wrong prediction
  - Low confidence

---

## ▶️ How to Run (Reproducibility Guide)

### 🔧 Requirements

Install:

- Icarus Verilog (`iverilog`)
- GTKWave (optional, for waveform viewing)

#### Ubuntu / WSL:
```bash
sudo apt update
sudo apt install iverilog gtkwave
```

---

### ▶️ Step 1: Compile

```bash
iverilog -o cpu_sim *.v
```

### ▶️ Step 2: Run Simulation

```bash
vvp cpu_sim
```

### ▶️ Step 3: View Waveform (Optional)

```bash
gtkwave output.vcd
```

### ▶️ Alternative (Precompiled)

A compiled executable is already provided:

```bash
vvp <provided_executable>
```

---

## 📊 Results

### Key Observation:

The perceptron predictor **increases execution cycles by ~10×** compared to the baseline CPU.

### Evidence:

See: `media/perceptron_cycles.png`
(Comparison with original baseline output)

---

## 📉 Analysis

The increase in cycles is due to:

- Dot-product computation per branch
- Sequential weight updates
- Increased combinational logic delay
- Lack of hardware optimizations (e.g., pipelined predictor)

---

## ⚠️ Important Note

This implementation prioritizes **functional correctness** over **hardware efficiency**.

As a result:

- Predictor latency is directly exposed to the pipeline
- No optimizations like:
  - Parallel computation
  - Speculative updates
  - Weight saturation

---

## 🧪 What This Project Shows

Instead of proving improvement, this project demonstrates:

> Advanced branch predictors can **hurt performance** if not carefully optimized in hardware.

---

## 🚧 Limitations

- No baseline predictor comparison inside the same framework
- No CPI / accuracy measurement
- No pipeline stall tracking
- No hardware optimization

---

## 🔮 Future Work

- Implement Gshare predictor for comparison
- Pipeline the perceptron computation
- Add Branch Target Buffer (BTB)
- Introduce weight saturation
- Measure:
  - CPI
  - Misprediction rate

---

## 👥 Credits

**Baseline CPU:**
- [https://github.com/seunghyukcho](https://github.com/seunghyukcho)
- [https://github.com/k0nen](https://github.com/k0nen)

**Extended with perceptron predictor by:**
- Naveen
- Efanio Jens
- Manoj

---

## ⚠️ Disclaimer

This project is an academic extension of an open-source CPU.
Do not reuse directly for coursework submissions without modification.
