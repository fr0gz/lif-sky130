import subprocess
import re
import os

spice_file = "spice/lif_reset_tb.spice"

# Corrientes que queremos comparar
iin_values = [4, 7, 10]

# Duración ideal del spike/reset
PULSE_WIDTH = "10n"

# Rise/fall del pulso
PULSE_EDGE = "1n"

results = []


# ============================================================
# Función: ejecutar ngspice y obtener t_cross
# ============================================================

def run_ngspice(netlist, filename):

    with open(filename, "w") as f:
        f.write(netlist)

    result = subprocess.run(
        ["ngspice", "-b", filename],
        capture_output=True,
        text=True
    )

    output = result.stdout + result.stderr

    match = re.search(
        r"t_cross\s*=\s*([0-9.eE+-]+)",
        output
    )

    if not match:
        print(output)
        raise RuntimeError("No se pudo encontrar t_cross")

    return float(match.group(1)), output


# ============================================================
# Sweep
# ============================================================

for iin in iin_values:

    print()
    print("=" * 55)
    print(f"IIN = {iin} nA")
    print("=" * 55)

    # --------------------------------------------------------
    # Leer netlist original
    # --------------------------------------------------------

    with open(spice_file, "r") as f:
        netlist = f.read()

    # --------------------------------------------------------
    # Poner IIN
    # --------------------------------------------------------

    netlist = re.sub(
        r"\.param\s+IIN\s*=\s*[^\n]+",
        f".param IIN = {iin}n",
        netlist
    )

    # --------------------------------------------------------
    # PRIMERA SIMULACIÓN
    #
    # Encontramos cuándo Vmem cruza VTH.
    # En esta primera pasada dejamos el PULSE fuera del
    # camino temporal; usamos un valor dummy muy temprano.
    # --------------------------------------------------------

    netlist_first = re.sub(
        r"Vspike\s+spike\s+0\s+PULSE\([^\n]+\)",
        "Vspike spike 0 PULSE(0 1.8 1u 1n 1n 10n 200u)",
        netlist
    )

    netlist_first = re.sub(
        r"Vreset\s+reset\s+0\s+PULSE\([^\n]+\)",
        "Vreset reset 0 PULSE(0 1.8 1u 1n 1n 10n 200u)",
        netlist_first
    )

    tmp_first = "spice/lif_reset_first.spice"

    t_cross, output = run_ngspice(
        netlist_first,
        tmp_first
    )

    t_cross_us = t_cross * 1e6

    print(
        f"Threshold crossing: "
        f"{t_cross_us:.6f} us"
    )

    # --------------------------------------------------------
    # SEGUNDA SIMULACIÓN
    #
    # Ahora ponemos el spike/reset exactamente en t_cross.
    # --------------------------------------------------------

    pulse_time = f"{t_cross_us:.6f}u"

    spike_pulse = (
        f"Vspike spike 0 "
        f"PULSE(0 1.8 {pulse_time} "
        f"{PULSE_EDGE} {PULSE_EDGE} "
        f"{PULSE_WIDTH} 200u)"
    )

    reset_pulse = (
        f"Vreset reset 0 "
        f"PULSE(0 1.8 {pulse_time} "
        f"{PULSE_EDGE} {PULSE_EDGE} "
        f"{PULSE_WIDTH} 200u)"
    )

    netlist_second = re.sub(
        r"Vspike\s+spike\s+0\s+PULSE\([^\n]+\)",
        spike_pulse,
        netlist
    )

    netlist_second = re.sub(
        r"Vreset\s+reset\s+0\s+PULSE\([^\n]+\)",
        reset_pulse,
        netlist_second
    )

    # --------------------------------------------------------
    # Archivo de datos específico
    # --------------------------------------------------------

    output_file = f"lif_reset_{iin}nA.dat"

    netlist_second = re.sub(
        r"print\s+time\s+v\(vmem\)\s+v\(reset\)\s+v\(spike\)"
        r"\s*>\s*\S+",
        f"print time v(vmem) v(reset) v(spike) > {output_file}",
        netlist_second
    )

    # --------------------------------------------------------
    # SEGUNDA SIMULACIÓN
    # --------------------------------------------------------

    tmp_second = "spice/lif_reset_sweep.spice"

    t_cross_2, output_2 = run_ngspice(
        netlist_second,
        tmp_second
    )

    # --------------------------------------------------------
    # Guardar resultado
    # --------------------------------------------------------

    results.append(
        (iin, t_cross_2 * 1e6)
    )

    print(
        f"Spike/reset at: "
        f"{t_cross_2 * 1e6:.6f} us"
    )

    if os.path.exists(output_file):

        size = os.path.getsize(output_file)

        print(
            f"Waveform saved: "
            f"{output_file} "
            f"({size} bytes)"
        )

    else:

        print(
            f"ERROR: no se generó "
            f"{output_file}"
        )


# ============================================================
# Resumen
# ============================================================

print()
print("=" * 55)
print("IIN vs t_cross -- LIF Spike / Reset")
print("=" * 55)

for iin, t_cross_us in results:

    print(
        f"{iin:6.1f} nA"
        f"{t_cross_us:14.3f} us"
    )

print()
print("Archivos generados:")

for iin in iin_values:

    filename = f"lif_reset_{iin}nA.dat"

    if os.path.exists(filename):
        print(f"  {filename}")
    else:
        print(f"  ERROR: {filename}")



    # --------------------------------------------------------
    # Leer netlist original
    # --------------------------------------------------------

      # Cambiar IIN
    # --------------------------------------------------------

    # --------------------------------------------------------
    # Archivo de salida específico para este IIN
    # --------------------------------------------------------

    # --------------------------------------------------------
    # Netlist temporal
    # -------------------------------------------------------
    # --------------------------------------------------------
    # Ejecutar ngspice
    # --------------------------------------------------------
    # --------------------------------------------------------
    # Buscar t_cross
    # --------------------------------------------------------
# ------------------------------------------------------------
# Resumen
# -----------------------------------------------------------
    # --------------------------------------------------------
    # Cambiar IIN

    # --------------------------------------------------------
    # Archivo de datos específico de este sweep
    # ---------------------------------------------
    # --------------------------------------------------------
    # Netlist temporal
    # ------------------------------------------------
    # --------------------------------------------------------
    # Ejecutar ngspice
    # --------------------------------------------------------


    # --------------------------------------------------------
    # Extraer t_cross
    # --------------------------------------------------------


# ------------------------------------------------------------
# Resumen
# ------------------------------------------------------------


