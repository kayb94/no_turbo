#!/bin/bash
# Simple workaround script to deactive TurboBoost on
# Lenovo Thinkpad T430 with Intel i5 3320M CPU.
# Free for non-commercial use.

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

# set no_turbo for CPU. GPU now still can trigger a frequency higher than that.
echo "1" > /sys/devices/system/cpu/intel_pstate/no_turbo

# get the maximum CPU frequency in MHz (already changed by no_turbo)
maxCPUFreq=$(($(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)))
maxCPUFreq=$(($maxCPUFreq / 1000))

# explicitly only look at the CPU frequencies to avoid mixing things up.
# get the row. assuming, cpu frequencies are always in the second column.
maxCPUFreqRow=$(($(cat /sys/kernel/debug/dri/0/i915_ring_freq_table \
    | awk '{print $2}' \
    | grep "$maxCPUFreq" --line-number \
    | sed -E 's:([^:]+).+$:\1:')))

# now get the value in the first column of that row (== the corresponding GPU frequency)
maxGPUFreq="$(cat /sys/kernel/debug/dri/0/i915_ring_freq_table \
    | awk -v n="$maxCPUFreqRow" 'NR==n{print $1}')"
        
# finally set that frequency.
echo "$maxGPUFreq" > /sys/class/drm/card0/gt_max_freq_mhz
echo "$maxGPUFreq" > /sys/class/drm/card0/gt_boost_freq_mhz

echo "Set maximum GPU frequency to ""$maxGPUFreq"" MHz and deactivated turbo."
exit 0
