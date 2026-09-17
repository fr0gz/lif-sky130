import numpy as np
import matplotlib.pyplot as plt

currents = [4, 7, 10]

colors = {
    4: "blue",
    7: "green",
    10: "orange"
}

plt.figure(figsize=(11, 6))

for iin in currents:

    filename = f"lif_reset_{iin}nA.dat"

    rows = []

    with open(filename, "r") as f:
        for line in f:

            parts = line.split()

            if len(parts) < 5:
                continue

            try:
                rows.append([float(x) for x in parts[:5]])
            except ValueError:
                continue

    data = np.array(rows)

    time_us = data[:, 1] * 1e6
    vmem = data[:, 2]

    plt.plot(
        time_us,
        vmem,
        color=colors[iin],
        linewidth=1.5,
        label=f"IIN = {iin} nA"
    )

plt.axhline(
    0.60,
    color="red",
    linestyle="--",
    linewidth=1,
    label="VTH = 0.60 V"
)

plt.xlabel("Tiempo [us]")
plt.ylabel("Vmem [V]")

plt.title(
    "SKY130 LIF - Comparación de integración"
)

plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()

plt.savefig(
    "lif_compare_4_7_10nA.png",
    dpi=150
)

plt.show()

