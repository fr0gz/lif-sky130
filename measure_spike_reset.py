import numpy as np

currents = [4, 7, 10]

VTH = 0.60
LEVEL = 0.90


def load_data(filename):

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

    if not rows:
        raise RuntimeError(f"No hay datos en {filename}")

    return np.array(rows)


def find_crossing(time, signal, level, start=0):

    for i in range(start, len(signal) - 1):

        if signal[i] < level and signal[i + 1] >= level:
            return i + 1

    return None


print()
print("=" * 78)
print("MEDICIÓN SPIKE / RESET -- SWEEP")
print("=" * 78)

print(
    f"{'IIN':>6}"
    f"{'t_cross':>14}"
    f"{'t_spike':>14}"
    f"{'T_spike':>14}"
    f"{'t_reset':>14}"
    f"{'T_reset':>14}"
)

for iin in currents:

    filename = f"lif_reset_{iin}nA.dat"

    data = load_data(filename)

    time = data[:, 1]
    vmem = data[:, 2]
    reset = data[:, 3]
    spike = data[:, 4]

    # --------------------------------------------------------
    # Vmem crossing VTH
    # --------------------------------------------------------

    i_cross = find_crossing(
        time,
        vmem,
        VTH
    )

    if i_cross is None:
        print(f"{iin:6.1f}   NO CROSS")
        continue

    t_cross = time[i_cross]

    # --------------------------------------------------------
    # Spike ON
    # --------------------------------------------------------

    i_spike_on = find_crossing(
        time,
        spike,
        LEVEL
    )

    # --------------------------------------------------------
    # Spike OFF
    # --------------------------------------------------------

    i_spike_off = None

    if i_spike_on is not None:

        i_spike_off = find_crossing(
            time,
            -spike,
            -LEVEL,
            start=i_spike_on
        )

    # --------------------------------------------------------
    # Reset ON
    # --------------------------------------------------------

    i_reset_on = find_crossing(
        time,
        reset,
        LEVEL
    )

    # --------------------------------------------------------
    # Reset OFF
    # --------------------------------------------------------

    i_reset_off = None

    if i_reset_on is not None:

        i_reset_off = find_crossing(
            time,
            -reset,
            -LEVEL,
            start=i_reset_on
        )

    # --------------------------------------------------------
    # Convert times
    # --------------------------------------------------------

    t_spike = (
        time[i_spike_on]
        if i_spike_on is not None
        else np.nan
    )

    t_spike_off = (
        time[i_spike_off]
        if i_spike_off is not None
        else np.nan
    )

    t_reset = (
        time[i_reset_on]
        if i_reset_on is not None
        else np.nan
    )

    t_reset_off = (
        time[i_reset_off]
        if i_reset_off is not None
        else np.nan
    )

    # --------------------------------------------------------
    # Durations
    # --------------------------------------------------------

    T_spike = (
        t_spike_off - t_spike
        if not np.isnan(t_spike_off)
        else np.nan
    )

    T_reset = (
        t_reset_off - t_reset
        if not np.isnan(t_reset_off)
        else np.nan
    )

    # --------------------------------------------------------
    # Print
    # --------------------------------------------------------

    def fmt_us(x):

        if np.isnan(x):
            return "---"

        return f"{x * 1e6:10.3f}"

    def fmt_ns(x):

        if np.isnan(x):
            return "---"

        return f"{x * 1e9:10.3f}"

    print(
        f"{iin:6.1f}"
        f"{fmt_us(t_cross):>14}"
        f"{fmt_us(t_spike):>14}"
        f"{fmt_ns(T_spike):>14}"
        f"{fmt_us(t_reset):>14}"
        f"{fmt_ns(T_reset):>14}"
    )

print()
print("Archivos analizados:")
for iin in currents:
    print(f"  lif_reset_{iin}nA.dat")

