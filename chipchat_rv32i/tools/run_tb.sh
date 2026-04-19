#!/usr/bin/env bash
set -euo pipefail

TOP="${1:?usage: run_tb.sh <top_module> <sv/v files...>}"
shift
OUT="build/${TOP}.out"
LOG="logs/${TOP}.log"

mkdir -p build logs

# -g2012 lets you use a few SV conveniences, but we will stay conservative
iverilog -g2012 -s "${TOP}" -o "${OUT}" "$@" > "${LOG}" 2>&1
vvp "${OUT}" | tee -a "${LOG}"
echo "LOG: ${LOG}"
