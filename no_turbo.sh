#!/bin/bash
# Simple workaround script to deactive TurboBoost on
# Lenovo Thinkpad T430 with Intel i5 3320M CPU.
# Free for non-commercial use.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

if [ "$#" == "0" ]; then
    # no specific CPU frequency given, go for lowest frequency below turbo
    # set no_turbo for CPU. GPU now still can trigger a frequency higher than that.
    echo "1" > /sys/devices/system/cpu/intel_pstate/no_turbo

    # get the maximum CPU frequency in MHz (already changed by no_turbo)
    TARGET_CPUFREQ=$(($(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)))
    TARGET_CPUFREQ=$(($TARGET_CPUFREQ / 1000))
else
    # use argument
    TARGET_CPUFREQ=$(($1))
fi

# find out the max cpu freq lower or equal to the actual target cpu freq with
# the corresponding GPUFREQ to determine the maximum GPUFREQ to not have a higher
# resulting CPUFREQ.
ROW=0
MAX_CPUFREQ=0
MAX_GPUFREQ_ROW=0
for i in \
    $(sudo cat /sys/kernel/debug/dri/0/i915_ring_freq_table \
      | awk '{print $2}')
do
    ROW=$(($ROW + 1))
    if [ $TARGET_CPUFREQ -ge $(($i)) ]; then
        MAX_CPUFREQ=$(($i))
        MAX_GPUFREQ_ROW=$(($ROW))
    fi
done
if [ $MAX_CPUFREQ -eq 0 ]; then
    echo Failed to find a max. GPU frequency allowing for given max. CPU frequency.
    exit 1
fi
MAX_GPUFREQ=$(cat /sys/kernel/debug/dri/0/i915_ring_freq_table | awk 'NR=='$MAX_GPUFREQ_ROW' { print $1 }')
        
# finally set that frequency.
echo "${MAX_GPUFREQ}" > /sys/class/drm/card0/gt_max_freq_mhz
echo "${MAX_GPUFREQ}" > /sys/class/drm/card0/gt_boost_freq_mhz

# also set matching CPU frequency
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
    echo "$((TARGET_CPUFREQ * 1000))" > "${i}"
done

echo "Set maximum GPU frequency to ""$MAX_GPUFREQ"" MHz, CPU frequency to "${TARGET_CPUFREQ}" MHz and deactivated turbo."
exit 0
