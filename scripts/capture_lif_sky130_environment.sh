#!/usr/bin/env bash
#
# ============================================================================
# capture_lif_sky130_environment.sh
# ============================================================================
#
# Reproducibility snapshot for the LIF / neuromorphic SKY130 project.
#
# Project:
#     lif-sky130
#
# Main workspace:
#     /foss/designs/lif-sky130
#
# Main PDK:
#     /foss/pdks/sky130A
#
# Purpose:
#     Capture the execution environment used for transistor-level,
#     SPICE, PDK, characterization and future physical-design experiments.
#
# The script distinguishes:
#
#     VERIFIED       -> obtained directly from the environment
#     NOT_AVAILABLE  -> could not be obtained
#     NOT_DEFINED    -> environment variable does not exist
#     DECLARED       -> project configuration supplied by this script/project
#
# The script does NOT modify:
#     - the PDK
#     - project source files
#     - Git history
#     - simulation files
#
# Output:
#     reproducibility/environment_<timestamp>.txt
#
# ============================================================================

set -u
set -o pipefail

# ============================================================================
# 0. PROJECT CONFIGURATION
# ============================================================================

PROJECT_NAME="lif-sky130"

PROJECT_ROOT="${PROJECT_ROOT:-/foss/designs/lif-sky130}"
PDK_ROOT_EXPECTED="${PDK_ROOT_EXPECTED:-/foss/pdks/sky130A}"

TIMESTAMP="$(date '+%Y-%m-%dT%H:%M:%S%z')"
TIMESTAMP_FILE="$(date '+%Y%m%d_%H%M%S')"

OUTPUT_DIR="${PROJECT_ROOT}/reproducibility"
OUTPUT_FILE="${1:-${OUTPUT_DIR}/environment_${TIMESTAMP_FILE}.txt}"

mkdir -p "${OUTPUT_DIR}"

# ============================================================================
# HELPERS
# ============================================================================

section()
{
    echo
    echo "============================================================================"
    echo "$1"
    echo "============================================================================"
}

subsection()
{
    echo
    echo "--- $1 ---"
}

status()
{
    printf "%-36s: %s\n" "$1" "$2"
}

command_exists()
{
    command -v "$1" >/dev/null 2>&1
}

print_command()
{
    local label="$1"
    shift

    if command_exists "$1"; then
        echo "${label}:"
        echo "  executable : $(command -v "$1")"
        "$@" 2>&1 || true
    else
        echo "${label}: NOT_AVAILABLE"
    fi
}

print_env()
{
    local var="$1"

    if [ -n "${!var+x}" ]; then
        printf "%-36s: %s\n" "$var" "${!var}"
    else
        printf "%-36s: NOT_DEFINED\n" "$var"
    fi
}

hash_file()
{
    local file="$1"

    if [ -f "$file" ] && command_exists sha256sum; then
        sha256sum "$file" | awk '{print $1}'
    else
        echo "NOT_AVAILABLE"
    fi
}

inspect_path()
{
    local path="$1"

    echo "Path        : ${path}"

    if [ -e "${path}" ]; then
        echo "Status      : VERIFIED"

        if [ -d "${path}" ]; then
            echo "Type        : directory"
        elif [ -f "${path}" ]; then
            echo "Type        : regular file"
            echo "SHA256      : $(hash_file "${path}")"
        elif [ -L "${path}" ]; then
            echo "Type        : symbolic link"
            echo "Target      : $(readlink -f "${path}" 2>/dev/null || readlink "${path}")"
        else
            echo "Type        : other"
        fi
    else
        echo "Status      : NOT_FOUND"
    fi
}

# ============================================================================
# BEGIN REPORT
# ============================================================================

{
    echo "LIF-SKY130 REPRODUCIBILITY ENVIRONMENT SNAPSHOT"
    echo "==============================================="
    echo
    echo "Project                     : ${PROJECT_NAME}"
    echo "Capture timestamp            : ${TIMESTAMP}"
    echo "Project root                : ${PROJECT_ROOT}"
    echo "Expected PDK root           : ${PDK_ROOT_EXPECTED}"
    echo "Report                      : ${OUTPUT_FILE}"
    echo
    echo "This report records environment information that could be"
    echo "verified at capture time."
    echo
    echo "STATUS DEFINITIONS"
    echo "  VERIFIED       = directly observed"
    echo "  NOT_AVAILABLE  = information/tool unavailable"
    echo "  NOT_DEFINED    = environment variable not defined"
    echo "  NOT_FOUND      = expected path does not exist"
    echo "  DECLARED       = supplied as project configuration"
    echo

    # ========================================================================
    # 1. PROJECT IDENTITY
    # ========================================================================

    section "1. PROJECT IDENTITY"

    status "Project name" "${PROJECT_NAME}"
    status "Project root" "${PROJECT_ROOT}"
    status "PDK expected root" "${PDK_ROOT_EXPECTED}"
    status "Capture time" "${TIMESTAMP}"

    if [ -d "${PROJECT_ROOT}" ]; then
        status "Project directory" "VERIFIED"
    else
        status "Project directory" "NOT_FOUND"
    fi

    # ========================================================================
    # 2. OPERATING SYSTEM
    # ========================================================================

    section "2. OPERATING SYSTEM / KERNEL / ARCHITECTURE"

    if [ -f /etc/os-release ]; then
        echo "[/etc/os-release]"
        cat /etc/os-release
    else
        status "OS release" "NOT_AVAILABLE"
    fi

    echo
    status "Kernel" "$(uname -srv 2>/dev/null || echo NOT_AVAILABLE)"
    status "Kernel release" "$(uname -r 2>/dev/null || echo NOT_AVAILABLE)"
    status "Architecture" "$(uname -m 2>/dev/null || echo NOT_AVAILABLE)"
    status "Machine" "$(uname -p 2>/dev/null || echo NOT_AVAILABLE)"

    if command_exists lscpu; then
        subsection "CPU information"
        lscpu 2>/dev/null || true
    fi

    # ========================================================================
    # 3. DATE / TIME / LOCALE
    # ========================================================================

    section "3. DATE / TIME / LOCALE"

    status "Timestamp" "${TIMESTAMP}"
    status "Timezone" "$(date '+%Z (%z)' 2>/dev/null || echo NOT_AVAILABLE)"
    status "UTC time" "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo NOT_AVAILABLE)"

    echo
    locale 2>/dev/null || true

    # ========================================================================
    # 4. EXECUTION ENVIRONMENT
    # ========================================================================

    section "4. EXECUTION ENVIRONMENT"

    if [ -f /.dockerenv ]; then
        status "Docker container detection" "VERIFIED"
    else
        status "Docker container detection" "NOT_DETECTED"
    fi

    print_env "container"

    if [ -n "${HOSTNAME:-}" ]; then
        status "Hostname" "${HOSTNAME}"
    else
        status "Hostname" "NOT_DEFINED"
    fi

    # ========================================================================
    # 5. DOCKER / IIC-OSIC-TOOLS
    # ========================================================================

    section "5. CONTAINER / IIC-OSIC-TOOLS"

    if command_exists docker; then

        status "Docker executable" "$(command -v docker)"
        docker --version 2>&1 || true

        if docker info >/dev/null 2>&1; then
            status "Docker daemon" "AVAILABLE"

            docker info \
                --format='ServerVersion={{.ServerVersion}}' \
                2>/dev/null || true
        else
            status "Docker daemon" "NOT_ACCESSIBLE"
        fi

        subsection "Relevant local EDA images"

        docker images \
            --format='{{.Repository}}:{{.Tag}} | ID={{.ID}} | Created={{.CreatedAt}}' \
            2>/dev/null |
            grep -Ei \
            'iic|osic|eda|sky130|open_pdks' \
            || echo "No matching images found."

    else
        status "Docker" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 6. PROJECT STRUCTURE
    # ========================================================================

    section "6. PROJECT STRUCTURE"

    if [ -d "${PROJECT_ROOT}" ]; then

        subsection "Top-level directories"

        find "${PROJECT_ROOT}" \
            -maxdepth 1 \
            -mindepth 1 \
            -type d \
            -printf '%f/\n' \
            2>/dev/null |
            sort

        subsection "Expected project components"

        for dir in \
            Documentos \
            Gds \
            matlab \
            scripts \
            spice \
            xschem
        do
            if [ -d "${PROJECT_ROOT}/${dir}" ]; then
                status "${dir}" "VERIFIED"
            else
                status "${dir}" "NOT_FOUND"
            fi
        done

    else
        status "Project structure" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 7. GIT
    # ========================================================================

    section "7. GIT REPOSITORY / SOURCE TRACEABILITY"

    if command_exists git; then

        git --version 2>&1 || true

        if git -C "${PROJECT_ROOT}" rev-parse --is-inside-work-tree \
            >/dev/null 2>&1; then

            status "Git repository" "VERIFIED"

            echo
            echo "Repository root:"
            git -C "${PROJECT_ROOT}" rev-parse --show-toplevel 2>/dev/null || true

            echo
            echo "Branch:"
            git -C "${PROJECT_ROOT}" branch --show-current 2>/dev/null || true

            echo
            echo "HEAD:"
            git -C "${PROJECT_ROOT}" rev-parse HEAD 2>/dev/null || true

            echo
            echo "HEAD commit metadata:"
            git -C "${PROJECT_ROOT}" log -1 \
                --date=iso-strict \
                --format='commit=%H%nparent=%P%nauthor=%an <%ae>%ndate=%ad%nsubject=%s' \
                2>/dev/null || true

            echo
            echo "Repository status:"
            git -C "${PROJECT_ROOT}" status --short 2>/dev/null || true

            echo
            echo "Tracked working tree:"
            if git -C "${PROJECT_ROOT}" diff --quiet 2>/dev/null; then
                echo "CLEAN"
            else
                echo "MODIFIED"
            fi

            echo
            echo "Staged changes:"
            if git -C "${PROJECT_ROOT}" diff --cached --quiet 2>/dev/null; then
                echo "NONE"
            else
                echo "PRESENT"
            fi

            echo
            echo "Untracked files:"
            git -C "${PROJECT_ROOT}" ls-files --others --exclude-standard \
                2>/dev/null || true

            echo
            echo "Remotes:"
            git -C "${PROJECT_ROOT}" remote -v 2>/dev/null || true

        else
            status "Git repository" "NOT_DETECTED"
        fi

    else
        status "Git" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 8. NGSPICE
    # ========================================================================

    section "8. NGSPICE"

    if command_exists ngspice; then

        status "ngspice executable" "$(command -v ngspice)"

        echo
        echo "Version information:"
        ngspice -v 2>&1 || true

        echo
        echo "Executable resolved path:"
        readlink -f "$(command -v ngspice)" 2>/dev/null || \
            command -v ngspice

        echo
        echo "Executable SHA256:"
        hash_file "$(readlink -f "$(command -v ngspice)" 2>/dev/null || command -v ngspice)"

    else
        status "ngspice" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 9. XSCHEM
    # ========================================================================

    section "9. XSCHEM"

    if command_exists xschem; then

        status "Xschem executable" "$(command -v xschem)"

        echo
        echo "Version:"
        xschem --version 2>&1 || \
            xschem -v 2>&1 || true

        echo
        echo "Resolved path:"
        readlink -f "$(command -v xschem)" 2>/dev/null || \
            command -v xschem

        echo
        echo "Executable SHA256:"
        hash_file "$(readlink -f "$(command -v xschem)" 2>/dev/null || command -v xschem)"

    else
        status "Xschem" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 10. KLAYOUT
    # ========================================================================

    section "10. KLAYOUT"

    if command_exists klayout; then

        status "KLayout executable" "$(command -v klayout)"

        echo
        klayout -v 2>&1 || true

        echo
        echo "Resolved path:"
        readlink -f "$(command -v klayout)" 2>/dev/null || \
            command -v klayout

        echo
        echo "Executable SHA256:"
        hash_file "$(readlink -f "$(command -v klayout)" 2>/dev/null || command -v klayout)"

    else
        status "KLayout" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 11. OTHER EDA TOOLS
    # ========================================================================

    section "11. ADDITIONAL EDA / ASIC TOOLS"

    for tool in \
        magic \
        netgen \
        iverilog \
        verilator \
        yosys \
        openlane \
        klayout \
        make \
        gcc \
        g++ \
        cmake
    do

        echo
        echo "[${tool}]"

        if command_exists "${tool}"; then
            echo "Executable : $(command -v "${tool}")"

            case "${tool}" in
                magic)
                    magic -version 2>&1 | head -n 5 || true
                    ;;
                netgen)
                    netgen -batch lvs 2>&1 | head -n 5 || true
                    ;;
                *)
                    "${tool}" --version 2>&1 | head -n 3 || true
                    ;;
            esac

        else
            echo "Status     : NOT_AVAILABLE"
        fi

    done

    # ========================================================================
    # 12. PYTHON / MATLAB
    # ========================================================================

    section "12. ANALYSIS ENVIRONMENT"

    subsection "Python"

    if command_exists python3; then

        echo "Executable:"
        command -v python3

        python3 --version 2>&1 || true

        echo
        echo "Python path:"
        python3 -c 'import sys; print(sys.executable)' 2>/dev/null || true

        echo
        echo "Python platform:"
        python3 -c 'import platform; print(platform.platform())' \
            2>/dev/null || true

        echo
        echo "Python version tuple:"
        python3 -c \
            'import sys; print(sys.version.replace("\n"," "))' \
            2>/dev/null || true

    else
        echo "Python3: NOT_AVAILABLE"
    fi

    subsection "MATLAB"

    if command_exists matlab; then
        echo "Executable:"
        command -v matlab

        matlab -batch "disp(version)" 2>&1 | head -n 10 || true
    else
        echo "MATLAB: NOT_AVAILABLE"
    fi

    # ========================================================================
    # 13. PDK IDENTITY
    # ========================================================================

    section "13. SKY130 PDK IDENTITY"

    inspect_path "${PDK_ROOT_EXPECTED}"

    if [ -d "${PDK_ROOT_EXPECTED}" ]; then

        echo
        echo "PDK root contents:"
        ls -la "${PDK_ROOT_EXPECTED}" 2>/dev/null || true

        echo
        echo "PDK subdirectories:"
        find "${PDK_ROOT_EXPECTED}" \
            -maxdepth 1 \
            -mindepth 1 \
            -type d \
            -printf '%f/\n' \
            2>/dev/null |
            sort

    fi

    # ========================================================================
    # 14. SKY130 LIBRARIES
    # ========================================================================

    section "14. SKY130 LIBRARIES / TECHNOLOGY TREE"

    SKY130_PR="${PDK_ROOT_EXPECTED}/libs.ref/sky130_fd_pr"
    SKY130_PR_SPICE="${SKY130_PR}/spice"
    SKY130_TECH="${PDK_ROOT_EXPECTED}/libs.tech"
    SKY130_COMBINED="${SKY130_TECH}/combined"

    inspect_path "${SKY130_PR}"
    inspect_path "${SKY130_PR_SPICE}"
    inspect_path "${SKY130_TECH}"
    inspect_path "${SKY130_COMBINED}"

    # ========================================================================
    # 15. SKY130 COMBINED MODEL ENTRY POINT
    # ========================================================================

    section "15. SKY130 COMBINED MODEL ENTRY POINT"

    SKY130_LIB="${SKY130_COMBINED}/sky130.lib.spice"

    inspect_path "${SKY130_LIB}"

    if [ -f "${SKY130_LIB}" ]; then

        echo
        echo "SHA256:"
        sha256sum "${SKY130_LIB}" 2>/dev/null || true

        echo
        echo "Corners / .lib declarations:"
        grep -n -E \
            '^[[:space:]]*\.lib[[:space:]]+' \
            "${SKY130_LIB}" \
            2>/dev/null || true

        echo
        echo "Included files:"
        grep -n -E \
            '^[[:space:]]*\.include[[:space:]]+' \
            "${SKY130_LIB}" \
            2>/dev/null || true

        echo
        echo "MC_MM_SWITCH declarations:"
        grep -n \
            'MC_MM_SWITCH' \
            "${SKY130_LIB}" \
            2>/dev/null || true

    fi

    # ========================================================================
    # 16. SKY130 DEVICE OF INTEREST
    # ========================================================================

    section "16. PRIMARY DEVICE UNDER INVESTIGATION"

    DEVICE="sky130_fd_pr__nfet_01v8"

    status "Device" "${DEVICE}"

    if [ -d "${SKY130_PR_SPICE}" ]; then

        echo
        echo "Matching files:"
        find "${SKY130_PR_SPICE}" \
            -maxdepth 1 \
            -type f \
            -iname "*nfet*01v8*" \
            2>/dev/null |
            sort

        echo
        echo "Subcircuit definitions:"
        grep -R -n -E \
            "^[[:space:]]*\.subckt[[:space:]]+${DEVICE}([[:space:]]|$)" \
            "${SKY130_PR_SPICE}" \
            2>/dev/null || true

        echo
        echo "Model definitions:"
        grep -R -n -E \
            "^[[:space:]]*\.model[[:space:]]+.*${DEVICE}" \
            "${SKY130_PR_SPICE}" \
            2>/dev/null |
            head -n 100 || true

    else
        echo "SPICE library directory unavailable."
    fi

    # ========================================================================
    # 17. MODEL DEPENDENCY: MC_MM_SWITCH
    # ========================================================================

    section "17. MODEL DEPENDENCY: MC_MM_SWITCH"

    echo "Searching SKY130 for MC_MM_SWITCH..."

    if [ -d "${PDK_ROOT_EXPECTED}" ]; then

        grep -R -n \
            'MC_MM_SWITCH' \
            "${PDK_ROOT_EXPECTED}" \
            2>/dev/null |
            head -n 200 || true

    else
        echo "PDK root unavailable."
    fi

    # ========================================================================
    # 18. MODEL DEPENDENCY: NSHORT_MODEL
    # ========================================================================

    section "18. MODEL DEPENDENCY: NSHORT_MODEL"

    echo "Searching SKY130 for nshort_model..."

    if [ -d "${PDK_ROOT_EXPECTED}" ]; then

        grep -R -n \
            'nshort_model' \
            "${PDK_ROOT_EXPECTED}" \
            2>/dev/null |
            head -n 200 || true

    else
        echo "PDK root unavailable."
    fi

    # ========================================================================
    # 19. MODEL FILES OF INTEREST
    # ========================================================================

    section "19. SKY130 MODEL FILES OF INTEREST"

    if [ -d "${SKY130_PR_SPICE}" ]; then

        find "${SKY130_PR_SPICE}" \
            -maxdepth 1 \
            -type f \
            \( \
                -iname '*tt*' \
                -o -iname '*leak*' \
                -o -iname '*nfet*' \
                -o -iname '*pm3*' \
            \) \
            2>/dev/null |
            sort

    else
        echo "SPICE library directory unavailable."
    fi

    # ========================================================================
    # 20. PDK ENVIRONMENT VARIABLES
    # ========================================================================

    section "20. PDK / EDA ENVIRONMENT VARIABLES"

    for var in \
        PDK_ROOT \
        PDK \
        PDK_PATH \
        PDK_HOME \
        SKY130 \
        SKY130_ROOT \
        SKY130A \
        OPEN_PDKS_ROOT \
        KLAYOUT_PATH \
        XSCHEM_PATH \
        XSCHEM_LIBRARY_PATH \
        NGSPICE_INPUT_DIR \
        SPICE_LIB_DIR \
        TECH_ROOT
    do
        print_env "${var}"
    done

    # ========================================================================
    # 21. PATHS
    # ========================================================================

    section "21. EXECUTABLE PATH"

    echo "PATH:"
    echo "${PATH}" | tr ':' '\n'

    echo
    echo "LD_LIBRARY_PATH:"
    if [ -n "${LD_LIBRARY_PATH+x}" ]; then
        echo "${LD_LIBRARY_PATH}" | tr ':' '\n'
    else
        echo "NOT_DEFINED"
    fi

    # ========================================================================
    # 22. PROJECT CONFIGURATION FILES
    # ========================================================================

    section "22. PROJECT CONFIGURATION FILES"

    for file in \
        "${PROJECT_ROOT}/README.md" \
        "${PROJECT_ROOT}/Makefile" \
        "${PROJECT_ROOT}/config.mk" \
        "${PROJECT_ROOT}/.spiceinit" \
        "${PROJECT_ROOT}/.xschemrc" \
        "${PROJECT_ROOT}/xschemrc" \
        "${PROJECT_ROOT}/Dockerfile" \
        "${PROJECT_ROOT}/docker-compose.yml"
    do

        if [ -e "${file}" ]; then

            echo
            echo "[FILE]"
            inspect_path "${file}"

        fi

    done

    # ========================================================================
    # 23. SPICE PROJECT FILES
    # ========================================================================

    section "23. PROJECT SPICE INVENTORY"

    if [ -d "${PROJECT_ROOT}/spice" ]; then

        echo "SPICE files:"
        find "${PROJECT_ROOT}/spice" \
            -type f \
            \( \
                -iname '*.sp' \
                -o -iname '*.spice' \
                -o -iname '*.cir' \
                -o -iname '*.ckt' \
                -o -iname '*.net' \
            \) \
            2>/dev/null |
            sort

    else
        echo "spice directory: NOT_FOUND"
    fi

    # ========================================================================
    # 24. XSCHEM INVENTORY
    # ========================================================================

    section "24. XSCHEM PROJECT INVENTORY"

    if [ -d "${PROJECT_ROOT}/xschem" ]; then

        find "${PROJECT_ROOT}/xschem" \
            -type f \
            2>/dev/null |
            sort

    else
        echo "xschem directory: NOT_FOUND"
    fi

    # ========================================================================
    # 25. GDS INVENTORY
    # ========================================================================

    section "25. GDS / LAYOUT INVENTORY"

    if [ -d "${PROJECT_ROOT}/Gds" ]; then

        find "${PROJECT_ROOT}/Gds" \
            -type f \
            \( \
                -iname '*.gds' \
                -o -iname '*.oas' \
                -o -iname '*.lef' \
                -o -iname '*.def' \
            \) \
            2>/dev/null |
            sort

    else
        echo "Gds directory: NOT_FOUND"
    fi

    # ========================================================================
    # 26. REPRODUCIBILITY DIRECTORY
    # ========================================================================

    section "26. REPRODUCIBILITY ARTIFACTS"

    if [ -d "${OUTPUT_DIR}" ]; then

        echo "Existing reproducibility files:"
        find "${OUTPUT_DIR}" \
            -maxdepth 1 \
            -type f \
            2>/dev/null |
            sort

    else
        echo "Reproducibility directory: NOT_FOUND"
    fi

    # ========================================================================
    # 27. SYSTEM PACKAGE INFORMATION
    # ========================================================================

    section "27. RELEVANT SYSTEM PACKAGES"

    if command_exists dpkg; then

        echo "Package manager: dpkg"

        dpkg -l 2>/dev/null |
            grep -Ei \
            'ngspice|xschem|klayout|magic|netgen|open_pdks|sky130|gcc|python3|iverilog|yosys' \
            || true

    elif command_exists rpm; then

        echo "Package manager: rpm"

        rpm -qa 2>/dev/null |
            grep -Ei \
            'ngspice|xschem|klayout|magic|netgen|open_pdks|sky130|gcc|python|iverilog|yosys' \
            || true

    else

        echo "Package manager: NOT_DETECTED"

    fi

    # ========================================================================
    # 28. PROJECT REPRODUCIBILITY SUMMARY
    # ========================================================================

    section "28. REPRODUCIBILITY SUMMARY"

    echo "PROJECT"
    status "Name" "${PROJECT_NAME}"
    status "Workspace" "${PROJECT_ROOT}"

    echo
    echo "TECHNOLOGY"
    status "Technology" "SKY130"
    status "PDK expected path" "${PDK_ROOT_EXPECTED}"

    if [ -d "${PDK_ROOT_EXPECTED}" ]; then
        status "PDK path verification" "VERIFIED"
    else
        status "PDK path verification" "NOT_FOUND"
    fi

    echo
    echo "TOOLS"

    if command_exists ngspice; then
        status "ngspice" "VERIFIED"
    else
        status "ngspice" "NOT_AVAILABLE"
    fi

    if command_exists xschem; then
        status "Xschem" "VERIFIED"
    else
        status "Xschem" "NOT_AVAILABLE"
    fi

    if command_exists klayout; then
        status "KLayout" "VERIFIED"
    else
        status "KLayout" "NOT_AVAILABLE"
    fi

    echo
    echo "SOURCE CONTROL"

    if git -C "${PROJECT_ROOT}" rev-parse HEAD >/dev/null 2>&1; then
        status "Git HEAD" \
            "$(git -C "${PROJECT_ROOT}" rev-parse HEAD)"
    else
        status "Git HEAD" "NOT_AVAILABLE"
    fi

    echo
    echo "MODEL FLOW"

    status "Combined SKY130 library" \
        "$([ -f "${SKY130_LIB}" ] && echo VERIFIED || echo NOT_FOUND)"

    if [ -f "${SKY130_LIB}" ]; then
        status "sky130.lib.spice SHA256" \
            "$(sha256sum "${SKY130_LIB}" | awk '{print $1}')"
    fi

    echo
    echo "PRIMARY DEVICE"

    status "Device under investigation" \
        "${DEVICE}"

    echo
    echo "IMPORTANT REPRODUCIBILITY NOTE"
    echo
    echo "This snapshot records the environment observed at capture time."
    echo "It does not prove that a simulation result is reproducible by itself."
    echo
    echo "For a complete experiment record, preserve together:"
    echo
    echo "  1. this environment snapshot;"
    echo "  2. the Git commit;"
    echo "  3. the exact SPICE netlist;"
    echo "  4. the exact simulation command;"
    echo "  5. the PDK installation/version;"
    echo "  6. relevant model files or immutable PDK reference;"
    echo "  7. simulation output/log;"
    echo "  8. generated plots/data;"
    echo "  9. temperature, voltage and bias conditions;"
    echo " 10. Monte Carlo/PVT configuration when applicable."
    echo
    echo "No files inside the PDK were modified by this script."

    # ========================================================================
    # 29. CAPTURE METADATA
    # ========================================================================

    section "29. CAPTURE METADATA"

    echo "Script name                 : capture_lif_sky130_environment.sh"
    echo "Project                     : ${PROJECT_NAME}"
    echo "Capture timestamp            : ${TIMESTAMP}"
    echo "Output                      : ${OUTPUT_FILE}"
    echo
    echo "END OF ENVIRONMENT SNAPSHOT"

} | tee "${OUTPUT_FILE}"

echo
echo "=========================================================================="
echo "Environment snapshot generated:"
echo "${OUTPUT_FILE}"
echo "=========================================================================="
