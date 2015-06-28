#!/bin/sh

FIL_IMG=""
IMG_OUT_DIR=${A20_PACKBUILD_DIR}
#Product Variants
A20_PRODUCT_ROOTFS_IMAGE=${A20_PACKAGES_DIR}/debian-server-rootfs.tar.gz
#A20_PRODUCT_ROOTFS_IMAGE=${A20_PACKAGES_DIR}/debian-server-rootfs-20140923.tar.gz
A20_PRODUCT_ONLY_KERNEL=0
U_BOOT_WITH_SPL=${A20_PACKAGES_DIR}/u-boot-a20/u-boot-sunxi-with-spl-a20-20130111.bin

IMG_SIZE=""

echo_img_out_dir()
{
	#IMG_OUT_DIR  add by jiangdou 2015-01-21
	echo -e "\033[1;32m ======= build IMG OK by jiangdou QQ:344283973,E-mail:jiangdouu88@126.com=========== \033[0m"
	echo -e "\033[1;34m Notice Output img_file at: \033[0m"
	FIL_IMG=`find ${IMG_OUT_DIR}/ -name "*img"`
	IMG_SIZE=`du --block-size=1024k $FIL_IMG  -h |  awk '{print int($1)}'`
	echo -e "\033[1;31m $FIL_IMG \033[0m"
	echo -e "\033[1;34m IMG_SIZE: $IMG_SIZE MB  !!! \033[0m"
	echo -e "\033[1;32m ======= build IMG OK by jiangdou QQ:344283973,E-mail:jiangdouu88@126.com=========== \033[0m"

}


a20_build_linux()
{
    if [ ! -d ${A20_KBUILD_DIR} ]; then
	mkdir -pv ${A20_KBUILD_DIR}
    fi

    echo "Start Building linux"
    cp -v ${A20_PRODUCT_DIR}/kernel_defconfig ${A20_KSRC_DIR}/arch/arm/configs/
    make -C ${A20_KSRC_DIR} O=${A20_KBUILD_DIR} ARCH=arm CROSS_COMPILE=${A20_CROSS_COMPILE} kernel_defconfig
    rm -rf ${A20_KSRC_DIR}/arch/arm/configs/kernel_defconfig
    make -C ${A20_KSRC_DIR} O=${A20_KBUILD_DIR} ARCH=arm CROSS_COMPILE=${A20_CROSS_COMPILE} -j8 INSTALL_MOD_PATH=${A20_TARGET_DIR} uImage modules
    ${A20_CROSS_COMPILE}objcopy -R .note.gnu.build-id -S -O binary ${A20_KBUILD_DIR}/vmlinux ${A20_KBUILD_DIR}/bImage
    #echo "Build linux successfully"
	echo -e "\033[1;32m Build linux successfully \033[0m"
	sleep 2
}

a20_build_clean()
{
    sudo rm -rf ${A20_OUTPUT_DIR}/*
    sudo rm -rf ${A20_BUILD_DIR}/*
}
#make
a20_build_nand_pack()
{
    if [ ! -d ${A20_PACKBUILD_DIR} ]; then
	mkdir -pv ${A20_PACKBUILD_DIR}
    fi

(
    local size=0
    LINUX_TOOLS_DIR=${A20_TOOLS_DIR}/pack/pctools/a20/linux
    export PATH=${LINUX_TOOLS_DIR}/mod_update:${LINUX_TOOLS_DIR}/eDragonEx:${LINUX_TOOLS_DIR}/fsbuild200:${LINUX_TOOLS_DIR}/android:$PATH

    sudo rm -rf ${A20_PACKBUILD_DIR}/*

    if [ "${A20_PRODUCT_ONLY_KERNEL}" -eq "0" ]; then
	make -C ${A20_KSRC_DIR} O=${A20_KBUILD_DIR} ARCH=arm CROSS_COMPILE=${A20_CROSS_COMPILE} -j8 INSTALL_MOD_PATH=${A20_TARGET_DIR} modules_install
	sudo tar -C ${A20_TARGET_DIR} --strip-components=1 -xf ${A20_PRODUCT_ROOTFS_IMAGE}
	(cd ${A20_PRODUCT_DIR}/overlay; tar -c *) |sudo tar -C ${A20_TARGET_DIR}  -x --no-same-owner
	sizeByte=$(sudo du -sb ${A20_TARGET_DIR} | awk '{print $1}')
	sizeMB=$(expr $sizeByte / 1000 / 1000 + 200)

	#echo "root size: ${sizeMB}MB"
	echo -e "\033[1;32m Your rootfs size: ${sizeMB}MB \033[0m"
	
	dd if=/dev/zero of=${A20_OUTPUT_DIR}/rootfs.ext4 bs=1M count=${sizeMB}
	mkfs.ext4 -F ${A20_OUTPUT_DIR}/rootfs.ext4
	sudo rm -rf ${A20_OUTPUT_DIR}/rootfs.ext4.dir
	sudo mkdir ${A20_OUTPUT_DIR}/rootfs.ext4.dir
	sudo mount -o loop ${A20_OUTPUT_DIR}/rootfs.ext4 ${A20_OUTPUT_DIR}/rootfs.ext4.dir
	sudo mv ${A20_TARGET_DIR}/* ${A20_OUTPUT_DIR}/rootfs.ext4.dir/
	sync
	sudo umount ${A20_OUTPUT_DIR}/rootfs.ext4.dir
	sudo rm -rf ${A20_OUTPUT_DIR}/rootfs.ext4.dir
	
    else
	dd if=/dev/zero of=${A20_OUTPUT_DIR}/rootfs.ext4 bs=1M count=2
    fi

    #livesuit
    cp -rv ${A20_PRODUCT_DIR}/configs/* ${A20_PACKBUILD_DIR}/
    cp -r ${A20_TOOLS_DIR}/pack/chips/a20/eFex ${A20_PACKBUILD_DIR}/
    cp -r ${A20_TOOLS_DIR}/pack/chips/a20/eGon ${A20_PACKBUILD_DIR}/
    cp -r ${A20_TOOLS_DIR}/pack/chips/a20/wboot ${A20_PACKBUILD_DIR}/

    cp -rf ${A20_PACKBUILD_DIR}/eFex/split_xxxx.fex ${A20_PACKBUILD_DIR}/wboot/bootfs ${A20_PACKBUILD_DIR}/wboot/bootfs.ini ${A20_PACKBUILD_DIR}
    cp -f ${A20_PACKBUILD_DIR}/eGon/boot0_nand.bin   ${A20_PACKBUILD_DIR}/boot0_nand.bin
    cp -f ${A20_PACKBUILD_DIR}/eGon/boot1_nand.bin   ${A20_PACKBUILD_DIR}/boot1_nand.fex
    cp -f ${A20_PACKBUILD_DIR}/eGon/boot0_sdcard.bin ${A20_PACKBUILD_DIR}/boot0_sdcard.fex
    cp -f ${A20_PACKBUILD_DIR}/eGon/boot1_sdcard.bin ${A20_PACKBUILD_DIR}/boot1_sdcard.fex

    cd ${A20_PACKBUILD_DIR}
    busybox unix2dos sys_config.fex
    busybox unix2dos sys_partition.fex
    script sys_config.fex
    script sys_partition.fex

    cp sys_config.bin bootfs/script.bin
    update_mbr sys_partition.bin 4

    cp -rf ${A20_KBUILD_DIR}/arch/arm/boot/uImage bootfs/
    cp -rf ${A20_PRODUCT_DIR}/u-boot.bin bootfs/linux/
    cp -rv ${A20_PRODUCT_DIR}/uEnv.txt bootfs/

    update_boot0 boot0_nand.bin   sys_config.bin NAND
    update_boot0 boot0_sdcard.fex sys_config.bin SDMMC_CARD
    update_boot1 boot1_nand.fex   sys_config.bin NAND
    update_boot1 boot1_sdcard.fex sys_config.bin SDMMC_CARD

    fsbuild bootfs.ini split_xxxx.fex
    mv bootfs.fex bootloader.fex

    ln -s ${A20_OUTPUT_DIR}/rootfs.ext4 rootfs.fex
    dragon image.cfg sys_partition.fex
    cd -
	
	#IMG_OUT_DIR  add by jiangdou 2015-01-21
	echo_img_out_dir
)
}



a20_build_nand_image()
{
    a20_build_linux
    a20_build_nand_pack
}


a20_build_card_image()
{
    a20_build_linux

    sudo rm -rf ${A20_OUTPUT_DIR}/card0-part1 ${A20_OUTPUT_DIR}/card0-part2
    mkdir -pv ${A20_OUTPUT_DIR}/card0-part1 ${A20_OUTPUT_DIR}/card0-part2

    #part1
    cp -v ${A20_KBUILD_DIR}/arch/arm/boot/uImage ${A20_OUTPUT_DIR}/card0-part1
    fex2bin ${A20_PRODUCT_DIR}/configs/sys_config.fex ${A20_OUTPUT_DIR}/card0-part1/script.bin
    #cp -v ${A20_PRODUCT_DIR}/boot.scr ${A20_OUTPUT_DIR}/card0-part1/boot.scr
    cp -v ${A20_PRODUCT_DIR}/configs/uEnv-mmc.txt ${A20_OUTPUT_DIR}/card0-part1/uEnv.txt

    (cd ${A20_OUTPUT_DIR}/card0-part1;  tar -c *) |gzip -9 > ${A20_OUTPUT_DIR}/bootfs-part1.tar.gz

    #part2
    sudo tar -C ${A20_OUTPUT_DIR}/card0-part2 -xf ${A20_PRODUCT_ROOTFS_IMAGE}
    sudo make -C ${A20_KSRC_DIR} O=${A20_KBUILD_DIR} ARCH=arm CROSS_COMPILE=${A20_CROSS_COMPILE} -j4 INSTALL_MOD_PATH=${A20_OUTPUT_DIR}/card0-part2 modules_install
    (cd ${A20_PRODUCT_DIR}/overlay; tar -c *) |sudo tar -C ${A20_OUTPUT_DIR}/card0-part2  -x --no-same-owner
    (cd ${A20_OUTPUT_DIR}/card0-part2; sudo tar -c * )|gzip -9 > ${A20_OUTPUT_DIR}/rootfs-part2.tar.gz
}

a20_install_card()
{
    local sd_dev=$1
    if a20_sd_sunxi_part $1
    then
	echo "Make sunxi partitons successfully"
    else
	echo "Make sunxi partitions failed"
	return 1
    fi

    mkdir /tmp/sdc1
    sudo mount /dev/${sd_dev}1 /tmp/sdc1
    sudo tar -C /tmp/sdc1 -xvf ${A20_OUTPUT_DIR}/bootfs-part1.tar.gz
    sync
    sudo umount /tmp/sdc1
    rm -rf /tmp/sdc1

    if a20_sd_make_boot2 $1 $U_BOOT_WITH_SPL
    then
	echo "Build successfully"
    else
	echo "Build failed"
	return 2
    fi

    mkdir /tmp/sdc2
    sudo mount /dev/${sd_dev}2 /tmp/sdc2
    sudo tar -C /tmp/sdc2 -xf ${A20_OUTPUT_DIR}/rootfs-part2.tar.gz
    sync
    sudo umount /tmp/sdc2
    rm -rf /tmp/sdc2

    return 0
}

a20_build_release()
{
    if [ ! -d ${A20_RELEASE_DIR} ]; then
        mkdir -pv ${A20_RELEASE_DIR}
    fi

    rm -rf ${A20_RELEASE_DIR}/*

    if [ -f ${A20_PACKBUILD_DIR}/livesuit_jiangdou_A20.img ]; then
        echo "copy livesuit image"
        cp  ${A20_PACKBUILD_DIR}/livesuit_jiangdou_A20.img ${A20_RELEASE_DIR}/jiangdou_A20-debian-nand.img
        gzip -c ${A20_RELEASE_DIR}/jiangdou_A20-debian-nand.img >  ${A20_RELEASE_DIR}/jiangdou_A20-debian-nand.img.gz
        md5sum  ${A20_RELEASE_DIR}/jiangdou_A20-debian-nand.img.gz > ${A20_RELEASE_DIR}/jiangdou_A20-debian-nand.img.gz.md5
	echo "login:sunxi" > ${A20_RELEASE_DIR}/login_passwd.txt
        echo "passwd:sunxi" >> ${A20_RELEASE_DIR}/login_passwd.txt
        awk 'NR == 1,NR == 3' ${A20_KSRC_DIR}/Makefile  > ${A20_RELEASE_DIR}/kernel_version.txt

        echo "copy kernel source"
        cp ${A20_KBUILD_DIR}/.config ${A20_RELEASE_DIR}/jiangdou_A20_defconfig
        (
        cd ${A20_KSRC_DIR}
        git archive --prefix kernel-source/ HEAD |gzip > ${A20_RELEASE_DIR}/kernel-source.tar.gz
        )
        md5sum ${A20_RELEASE_DIR}/kernel-source.tar.gz > ${A20_RELEASE_DIR}/kernel-source.tar.gz.md5
        cp -rv ${A20_PRODUCT_DIR}/configs ${A20_RELEASE_DIR}/
        date +%Y%m%d > ${A20_RELEASE_DIR}/build.log

	echo "done"
    fi
}


