#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "--- Memory Optimization Script ---"

echo "Current memory usage:"
free -h

echo -e "\n1. Syncing file system buffers..."
sync

echo "2. Clearing PageCache, dentries, and inodes..."
# 1 = PageCache
# 2 = dentries and inodes
# 3 = PageCache, dentries and inodes
echo 3 > /proc/sys/vm/drop_caches

echo "3. Clearing and resetting Swap (this may take a moment)..."
swapon -s | grep -q "/dev"
if [ $? -eq 0 ]; then
    swapoff -a && swapon -a
    echo "Swap cleared."
else
    echo "No active swap found, skipping."
fi

echo -e "\nMemory usage after optimization:"
free -h

echo -e "\nOptimization complete!"
