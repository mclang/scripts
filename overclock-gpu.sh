#!/bin/bash
# https://www.reddit.com/r/linux_gaming/comments/406hue/nvidia_gpu_overclocking/
# https://wiki.archlinux.org/index.php/NVIDIA#Enabling_overclocking
#

if ! grep -iqR 'coolbits' /etc/X11/*; then
	echo -e "\nNOTE: 'Option "Coolbits" "12"' MUST be set in Nvidia Device section of XOrg config!\n"
	exit 1
fi

nvidia-settings \
-a "[gpu:0]/GPUGraphicsClockOffset[1]=75" \
-a "[gpu:0]/GPUMemoryTransferRateOffset[1]=530" \
-a "[gpu:0]/GPUOverVoltageOffset[1]=12000" \
-a "[gpu:0]/GpuPowerMizerMode=1"

# https://www.reddit.com/r/EtherMining/comments/6jk9l9/overlocking_1050_ti_on_linux/
# CLOCK=100
# MEM=900
# CMD='/usr/bin/nvidia-settings'
#
# echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# echo "performance" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
# echo 2800000       > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
# echo 2800000       > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
#
# for i in {0..5}
#   do
#     nvidia-smi -i ${i} -pm 0
#     nvidia-smi -i ${i} -pl 75
# ${CMD} -a [gpu:${i}]/GPUPowerMizerMode=1
# ${CMD} -a [gpu:${i}]/GPUFanControlState=1
# ${CMD} -a [fan:${i}]/GPUTargetFanSpeed=80
#
# for x in {3..3}
#   do
#     ${CMD} -a [gpu:${i}]/GPUGraphicsClockOffset[${x}]=${CLOCK}
#     ${CMD} -a [gpu:${i}]/GPUMemoryTransferRateOffset[${x}]=${MEM}
#   done
# done

