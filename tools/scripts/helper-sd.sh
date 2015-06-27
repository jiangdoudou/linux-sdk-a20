#!/bin/bash

A20_SD_NAME=
A20_SD_REMOVABLE=
A20_SD_SIZE=
A20_SD_MODEL=

a20_sd_list()
{
    echo "Block Device:"

for device in $(ls /dev/sd[a-z]); do
    A20_SD_NAME=`echo $device|awk -F/ '{print $3}'`
    A20_SD_SIZE=`cat /sys/block/$A20_SD_NAME/size`
    A20_SD_SIZE=$(expr $A20_SD_SIZE / 1024 / 1024 )
    A20_SD_REMOVABLE=`cat /sys/block/$A20_SD_NAME/removable`
    A20_SD_MODEL=`cat /sys/block/$A20_SD_NAME/device/model`

    printf "    $A20_SD_NAME\t$A20_SD_SIZE\t$A20_SD_REMOVABLE\t$A20_SD_MODEL\n"
done
}

a20_sd_check()
{
    local sd_dev=$1
    local full_path="/dev/$sd_dev"
    is_removable=0

    if [ ! -b "$full_path" ]; then
	echo "Invalid: $full_path"
	return 1
    fi

    if [ ! -d "/sys/block/$sd_dev" ]; then
	echo "Invalid: $sd_dev"
	return 2
    fi

    is_removable=`cat /sys/block/$sd_dev/removable`

    if [ ${is_removable} -ne "1" ]; then
	echo "is not a removable disk"
	return 3
    fi

    return 0
}

a20_sd_sunxi_part()
{
    local card="$1"

    if a20_sd_check $card
    then
	echo "Cleaning /dev/$card"
    else
	return 1
    fi

    sudo sfdisk -R /dev/$card
    sudo sfdisk --force --in-order -uS /dev/$card <<EOF
2048,24576,L
,,L
EOF

    sync
    
    sudo mkfs.ext2 /dev/${card}1
    sudo mkfs.ext4 /dev/${card}2

    return 0
}

a20_sd_sunxi_flash_part()
{
    local card="$1"
    if a20_sd_check $card
    then
	echo "Cleaning /dev/$card"
    else
	return 1
    fi
	Part2Size=$(expr $2 + 24576)
	echo $Part2Size
    sudo sfdisk -R /dev/$card
    sudo sfdisk --force --in-order -uS /dev/$card <<EOF
2048,24576,L
,${Part2Size},L
EOF

   sync

    sudo mkfs.ext2 /dev/${card}1
    sudo mkfs.ext4 /dev/${card}2

    return 0
}

a20_sd_make_boot()
{
    local card="$1"
    local sunxi_spl=$2
    local sunxi_uboot=$3

    if a20_sd_check $card
    then
	echo "Check ok: /dev/$card"
    else
	return 1
    fi

    sudo dd if=$sunxi_spl of=/dev/$card bs=1024 seek=8
    sudo dd if=$sunxi_uboot of=/dev/$card bs=1024 seek=32

    return 0
}

a20_sd_make_boot2()
{
    local card="$1"
    local sunxi_uboot_with_spl=$2

    if a20_sd_check $card
    then
	echo "Check ok: /dev/$card"
    else
	return 1
    fi

    sudo dd if=$sunxi_uboot_with_spl of=/dev/$card bs=1024 seek=8

    return 0
}

