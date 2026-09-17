#!/usr/bin/env python3

import os
import re
import numpy as np
import matplotlib.pyplot as plt


RAW_DIR = "sweep_iin"

sweeps = [
    ("5n", 5e-9),
    ("5.5n", 5.5e-9),
    ("6n", 6e-9),
    ("6.5n", 6.5e-9),
    ("7n", 7e-9),
    ("7.5n", 7.5e-9),
    ("8n", 8e-9),
    ("8.5n", 8.5e-9),
    ("9n", 9e-9),
    ("9.5n", 9.5e-9),
    ("10n", 10e-9),
]


def read_ngspice_ascii(filename):
    """Read ngspice ASCII raw file with sequential Values format."""

    with open(filename, "r") as f:
        lines = f.readlines()

    # Find number of points
    npoints = None
    for line in lines:
        if line.startswith("No. Points:"):
            npoints = int(line.split(":")[1])
            break

    # Find Values:
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

        # First line of each point:
        # "0  time"
        parts = line.split()

        if len(parts) >= 2:
            try:
                index = int(parts[0])
                time = float(parts[1])
            except ValueError:
                i += 1
                continue

            # Next two lines are v(vmem), v(bias)
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

colors = plt.cm.viridis(np.linspace(0, 1, len(sweeps)))

for (name, current), color in zip(sweeps, colors):

    filename = os.path.join(
        RAW_DIR,
        f"lif_{name}.raw"
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
        f"{current*1e9:6.3g} nA: "
        f"{len(t)} points, "
        f"Vmem_final = {vmem[-1]*1e3:.3f} mV"
    )

    ax.plot(
        t * 1e6,
        vmem * 1e3,
        color=color,
        linewidth=1.5,
        label=f"{current*1e9:g} nA"
    )


ax.set_xlabel("Time [µs]")
ax.set_ylabel("Membrane voltage Vmem [mV]")
ax.set_title("SKY130 LIF — Input Current Sweep")

ax.grid(True, alpha=0.3)
ax.legend(title="IIN")

fig.tight_layout()

plt.savefig(
    "lif_iin_sweep.png",
    dpi=200
)

plt.show()

