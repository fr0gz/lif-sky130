#!/usr/bin/env python3

import os
import numpy as np
import matplotlib.pyplot as plt

RAW_DIR = "sweep_2d"

currents = [
    ("4n", 4e-9),
    ("5n", 5e-9),
    ("6n", 6e-9),
    ("7n", 7e-9),
    ("8n", 8e-9),
    ("9n", 9e-9),
    ("10n", 10e-9),
]

vbias_values = [
    0.34,
    0.35,
    0.36,
    0.37,
    0.38,
    0.39,
]


def read_ngspice_ascii(filename):

    with open(filename, "r") as f:
        lines = f.readlines()

    start = next(
        i for i, line in enumerate(lines)
        if line.strip() == "Values:"
    )

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

    if len(data) == 0:
        raise RuntimeError(f"No data in {filename}")

    return data[:, 0], data[:, 1], data[:, 2]


# ------------------------------------------------------------
# Build Vmem_final matrix
# rows    = VBIAS
# columns = IIN
# ------------------------------------------------------------

Z = np.zeros((len(vbias_values), len(currents)))

for j, (iname, current) in enumerate(currents):

    for i, vbias in enumerate(vbias_values):

        filename = os.path.join(
            RAW_DIR,
            f"lif_{iname}_{vbias:.2f}.raw"
        )

        if not os.path.exists(filename):
            print(f"WARNING: missing {filename}")
            Z[i, j] = np.nan
            continue

        t, vmem, bias = read_ngspice_ascii(filename)

        Z[i, j] = vmem[-1] * 1e3

        print(
            f"IIN={current*1e9:4.1f} nA "
            f"VBIAS={vbias:.2f} V "
            f"Vmem_final={vmem[-1]*1e3:8.3f} mV"
        )


# ------------------------------------------------------------
# Print matrix
# ------------------------------------------------------------

print("\nVmem_final [mV]\n")
print("VBIAS \\ IIN")

for i, vbias in enumerate(vbias_values):

    values = " ".join(
        f"{x:8.1f}" for x in Z[i]
    )

    print(f"{vbias:.2f}      {values}")


# ------------------------------------------------------------
# Heatmap
# ------------------------------------------------------------

fig, ax = plt.subplots(figsize=(9, 6))

im = ax.imshow(
    Z,
    origin="lower",
    aspect="auto",
    cmap="viridis",
    extent=[
        3.5,
        10.5,
        0.335,
        0.395,
    ],
)

ax.set_xlabel("Input current IIN [nA]")
ax.set_ylabel("Leakage bias VBIAS [V]")
ax.set_title(
    "SKY130 LIF — DC Operating Point Map"
)

ax.set_xticks([4, 5, 6, 7, 8, 9, 10])
ax.set_yticks(vbias_values)

cbar = fig.colorbar(im, ax=ax)
cbar.set_label("Final membrane voltage Vmem [mV]")

fig.tight_layout()

plt.savefig(
    "lif_2d_operating_map.png",
    dpi=250
)

plt.show()
