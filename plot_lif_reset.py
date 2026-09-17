import numpy as np
import matplotlib.pyplot as plt

filename = "lif_reset_plot.dat"

# ------------------------------------------------------------
# Leer solamente líneas numéricas
# ------------------------------------------------------------

rows = []

with open(filename, "r") as f:
    for line in f:
        parts = line.split()

        # Necesitamos 5 columnas:
        # index, time, vmem, reset, spike
        if len(parts) < 5:
            continue

        try:
            values = [float(x) for x in parts[:5]]
            rows.append(values)
        except ValueError:
            continue

if not rows:
    raise RuntimeError("No se encontraron datos numéricos en lif_reset_plot.dat")

data = np.array(rows)

print(f"Datos cargados: {len(data)}")

# ------------------------------------------------------------
# Columnas
# ------------------------------------------------------------

index = data[:, 0]
time  = data[:, 1]
vmem  = data[:, 2]
reset = data[:, 3]
spike = data[:, 4]

#Convertir tiempo a us
time_us = time * 1e6

# ------------------------------------------------------------
# Métricas
# ------------------------------------------------------------

threshold = 0.60

crossings = np.where(
    (vmem[:-1] < threshold) &
    (vmem[1:] >= threshold)
)[0]

if len(crossings) > 0:
    t_cross = time_us[crossings[0]]
    print(f"t_cross aproximado: {t_cross:.3f} us")
else:
    t_cross = None
    print("No se encontró cruce de VTH")

print(f"Vmem max: {np.max(vmem):.4f} V")
print(f"Spike max: {np.max(spike):.4f} V")
print(f"Reset max: {np.max(reset):.4f} V")

plt.figure(figsize=(10, 5))

plt.plot(
    time_us,
    vmem,
    label="Vmem",
    linewidth=1.5
)

plt.plot(
    time_us,
    reset,
    label="Reset",
    linewidth=1.2
)

plt.plot(
    time_us,
    spike,
    label="Spike",
    linewidth=1.2
)

plt.axhline(
    threshold,
    color="red",
    linestyle="--",
    linewidth=1,
    label="VTH = 0.60 V"
)

plt.xlabel("Tiempo [us]")
plt.ylabel("Voltaje [V]")
plt.title("SKY130 LIF - Spike / Reset prototype")

plt.grid(True, alpha=0.3)
plt.legend()

plt.tight_layout()

plt.savefig(
    "lif_reset.png",
    dpi=150
)

plt.show()
# ------------------------------------------------------------
# Reset
# -----------------------------------------------

#ax2.set_ylabel("Reset [V]")
#ax2.set_ylim(-0.1, 0.7)

# ------------------------------------------------------------
# Title
#

#import numpy as n
#import matplotlib.pyplot as plt

#filename = "lif_reset.dat"

# -----------------------------------------------------st line con# ------------------------------------------------------------

#with open(filename) as f:
 #   lines = f.readlines()

#start = None

#for i, line in enumerate(lines):
 #   parts = line.split()

  #  if len(parts) != 3:
   #     continue

    #try:
     #   float(parts[0])
      #  float(parts[1])
       # float(parts[2])
        #start = i
        #break
   # except ValueError:
    #    continue

#if start is None:
 #   raise RuntimeError("Could not find numerical data in lif_reset.dat")

#print(f"Data starts at line {start}")

# ------------------------------------------------------------
# Load data
# ------------------------------------------------------------

#data = np.loadtxt(filename, skiprows=start)

#t = data[:, 0] * 1e6       # s -> us
#vmem = data[:, 1] * 1e3    # V -> mV
#reset = data[:, 2]          # V

# ------------------------------------------------------------
# Plot
# ------------------------------

