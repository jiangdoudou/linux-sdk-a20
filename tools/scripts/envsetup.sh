#!/bin/bash




echo -e "\033[1;32m ======= build IMG START by jiangdou =========== \033[0m"
echo -e "\033[1;32m this SDK for A20_NAND  \033[0m"
echo -e "\033[1;32m author by jiangdou QQ:344283973 E-mail:jiangdouu88@126.com \033[0m"
echo -e "\033[1;32m time at 2014-05-23 \033[0m"
echo ""
echo ""
echo -e "\033[1;32m ======= build IMG START by jiangdou =========== \033[0m"
echo ""
##################################################################
#Public Enviroment Settings
#this SDK for A20_NAND
# 
#author by jiangdou
#time at 2014-05-23
##################################################################
A20_SDK_ROOTDIR=
A20_PRODUCT_NAME=
A20_PRODUCT_DIR=
A20_OUTPUT_DIR=
A20_BUILD_DIR=
A20_TARGET_DIR=
A20_KSRC_DIR=
A20_KBUILD_DIR=
A20_TOOLS_DIR=
A20_PACKAGES_DIR=
A20_RELEASE_DIR=

a20_get_product()
{
    local array
    local index
    local target
    local product

    array=(`ls products |sort`)
	
	echo -e "\033[1;34m Please select to your Products \033[0m"
    for index in ${!array[*]}
    do
	printf "%4d - %s\n" $index ${array[$index]}
    done

    read -p "please select a product:" target

    for index in ${!array[*]}
    do
	if [ "${index}" == "${target}" ]; then
	    A20_PRODUCT_NAME="${array[$target]}"
	fi
    done
}

a20_get_product

while [ -z "$A20_PRODUCT_NAME" ]; do
    a20_get_product
done

export A20_SDK_ROOTDIR=${PWD}
export A20_PRODUCT_NAME
export A20_OUTPUT_DIR=${A20_SDK_ROOTDIR}/output/${A20_PRODUCT_NAME}
export A20_BUILD_DIR=${A20_SDK_ROOTDIR}/build/${A20_PRODUCT_NAME}
export A20_TARGET_DIR=${A20_OUTPUT_DIR}/target
export A20_PRODUCT_DIR=${A20_SDK_ROOTDIR}/products/${A20_PRODUCT_NAME}
export A20_RELEASE_DIR=${A20_SDK_ROOTDIR}/release/${A20_PRODUCT_NAME}
export A20_TOOLS_DIR=${A20_SDK_ROOTDIR}/tools
export A20_KSRC_DIR=${A20_SDK_ROOTDIR}/linux-sunxi
export A20_KBUILD_DIR=${A20_BUILD_DIR}/linux
export A20_PACKBUILD_DIR=${A20_BUILD_DIR}/pack
export A20_CROSS_COMPILE=arm-linux-gnueabi-
export A20_PACKAGES_DIR=${A20_SDK_ROOTDIR}/binaries

echo "Creating working dirs"
mkdir -p ${A20_OUTPUT_DIR} ${A20_BUILD_DIR} ${A20_KBUILD_DIR} ${A20_PACKBUILD_DIR} ${A20_TARGET_DIR}
source ${A20_PRODUCT_DIR}/envsetup.sh
source ${A20_TOOLS_DIR}/scripts/helper-sd.sh



if [ -f ${A20_PRODUCT_DIR}/readme.txt ]; then
echo ""
cat  ${A20_PRODUCT_DIR}/readme.txt
fi



crelease()
{
    cd $A20_RELEASE_DIR
}

clinux()
{
    cd $A20_KSRC_DIR
}

cout()
{
    cd $A20_OUTPUT_DIR
}

croot()
{
    cd $A20_SDK_ROOTDIR
}

a20uild()
{
    cd $A20_BUILD_DIR
}

ctarget()
{
    cd $A20_TARGET_DIR
}

cpack()
{
    cd $A20_PACKBUILD_DIR
}

ckbuild()
{
    cd $A20_KBUILD_DIR
}
