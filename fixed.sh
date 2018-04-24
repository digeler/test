#!/bin/bash

# Variables
#DATA_DISK=$1;
#DATA_PART="$DATA_DISK"1;
#DATA_PART_MOUNT=$2;
# An set of disks to ignore from partitioning and formatting
BLACKLIST="/dev/sda|/dev/sdb"
# Base directory to hold the data* files
DATA_BASE="/var"
#functions

scan_for_new_disks() {
    # Looks for unpartitioned disks
    declare -a RET
    DEVS=($(ls -1 /dev/sd*|egrep -v "${BLACKLIST}"|egrep -v "[0-9]$"))
    for DEV in "${DEVS[@]}";
    do
        # Check each device if there is a "1" partition.  If not,
        # "assume" it is not partitioned.
        if [ ! -b ${DEV}1 ];
        then
            RET+="${DEV} "
        fi
    done
    echo "${RET}"
}

get_next_mountpoint() {
    DIRS=($(ls -1d ${DATA_BASE}/data* 2>&1| sort --version-sort))
    if [ -z "${DIRS[0]}" ];
    then
        echo "${DATA_BASE}/gitlab"
        return
    else
        IDX=$(echo "${DIRS[${#DIRS[@]}-1]}"|tr -d "[a-zA-Z/]" )
        IDX=$(( ${IDX} + 1 ))
        echo "${DATA_BASE}/gitlab${IDX}"
    fi
}
DATA_DISK=($(scan_for_new_disks))
echo $DATA_DISK
DATA_PART="$DATA_DISK"1;
echo $DATA_PART


# Partition and format
sudo parted $DATA_DISK mklabel msdos;
#sleep 30;
sudo parted -a opt $DATA_DISK mkpart primary ext4 0% 100%;
#sleep 30;
sudo mkfs.ext4 -L gitlabdata $DATA_PART;

# Create mount point directory 
DATA_PART_MOUNT=$(get_next_mountpoint)
sudo mkdir -p $DATA_PART_MOUNT;

# Make record in /etc/fstab
DATA_DISK_UUID=$(sudo blkid $DATA_PART -o value | grep "[a-fA-F0-9]\{8\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{12\}");
sudo echo "UUID=$DATA_DISK_UUID $DATA_PART_MOUNT auto defaults 0 2" >> /etc/fstab;

# Mount partitions listed in fstab
mount -a
