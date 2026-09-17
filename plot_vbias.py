#!/usr/bin/env python3

import os
import numpy as np
import matplotlib.pyplot as plt


RAW_DIR = "sweep_vbias"

sweeps = [
    ("0.30", 0.30),
    ("0.31", 0.31),
    ("0.32", 0.32),
    ("0.33", 0.33),
    ("0.34", 0.34),
    ("0.35", 0.35),
    ("0.36", 0.36),
    ("0.37", 0.37),
    ("0.38", 0.38),
    ("0.39", 0.39),
    ("0.40", 0.40),
]



def read_ngspice_ascii(filename):
    """Read ngspice ASCII raw file with sequential Values format."""

    with open(filename, "r") as f:
        lines = f.readlines()

    try:
        start = next(
            i for i, line in enumerate(lines)
            if line.strip() == "Values:"
        )
    except StopIteration:
        raise RuntimeError(f"No 'Values:' section in {filename}")

    data = []
    i = start + 1

    while i < len(lines):

        line = lines[i].strip()

        if not line:
            i += 1
            continue

        parts = line.split()

        if len(parts) >= 2:
            try:
                index = int(parts[0])
                time = float(parts[1])
            except ValueError:
                i += 1
                continue

            if i + 2 >= len(lines):
                break

            vmem = float(lines[i + 1].strip())
            bias = float(lines[i + 2].strip())

            data.append((time, vmem, bias))

            i += 3

        else:
            i += 1

    data = np.array(data)

    if data.size == 0:
        raise RuntimeError(f"No data parsed from {filename}")

    return data[:, 0], data[:, 1], data[:, 2]


# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

fig, ax = plt.subplots(figsize=(10, 6))

colors = plt.cm.plasma(
    np.linspace(0, 1, len(sweeps))
)

for (name, vbias), color in zip(sweeps, colors):

    filename = os.path.join(
        RAW_DIR,
        f"lif_vbias_{name}.raw"
    )

    if not os.path.exists(filename):
        print(f"WARNING: missing {filename}")
        continue

    try:
        t, vmem, bias = read_ngspice_ascii(filename)

    except Exception as e:
        print(f"WARNING: {filename}: {e}")
        continue

    print(
        f"VBIAS = {vbias:.2f} V: "
        f"{len(t)} points, "
        f"Vmem_final = {vmem[-1]*1e3:.3f} mV"
    )

    ax.plot(
        t * 1e6,
        vmem * 1e3,
        color=color,
        linewidth=1.5,
        label=f"{vbias:.2f} V"
    )


ax.set_xlabel("Time [µs]")
ax.set_ylabel("Membrane voltage Vmem [mV]")
ax.set_title("SKY130 LIF — VBIAS Sweep, IIN = 5 nA")

ax.grid(True, alpha=0.3)
ax.legend(title="VBIAS")

fig.tight_layout()

plt.savefig(
    "lif_vbias_sweep.png",
    dpi=200
)

plt.show()

