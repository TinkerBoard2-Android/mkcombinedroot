#!/bin/bash
KERNEL_IMAGE=../kernel/arch/arm64/boot/Image
PRIVATE_MODULE_DIR=./ramdisk/lib/modules
PRIVATE_LOAD_FILE=./ramdisk/lib/modules/modules.load
TEMP_MODULES_PATH=./temp/lib/modules/0.0
KERNEL_DRIVERS_PATH=../kernel/drivers
if [ ! -n "$1" ]; then
  DTB_PATH=../kernel/arch/arm64/boot/dts/rockchip/rk3399-evb-ind-lpddr4-android-avb.dtb
else    
  DTB_PATH=../kernel/arch/arm64/boot/dts/rockchip/$1.dtb
fi
echo "==========================================="
echo "Use DTS as $DTB_PATH"
echo "==========================================="
echo "Preparing temp dirs and use placeholder 0.0..."
if [ -d temp ]; then
  rm -rf temp
fi
if [ -d $PRIVATE_MODULE_DIR ]; then
  rm -rf $PRIVATE_MODULE_DIR
fi
mkdir -p $TEMP_MODULES_PATH
mkdir -p $PRIVATE_MODULE_DIR
echo "Prepare temp dirs done."
echo "==========================================="
modules_array=($(find $KERNEL_DRIVERS_PATH -type f -name *.ko))
for MODULE in "${modules_array[@]}"
do
  echo "Copying $MODULE..."
  cp $MODULE $TEMP_MODULES_PATH/
  cp $MODULE $PRIVATE_MODULE_DIR/
done
echo "==========================================="
echo "Generating depmod..."
depmod -b temp 0.0
find $TEMP_MODULES_PATH -type f -name *.ko | xargs basename -a > $TEMP_MODULES_PATH/modules.load
echo "generate depmod done."

cp $TEMP_MODULES_PATH/modules.alias $PRIVATE_MODULE_DIR/
cp $TEMP_MODULES_PATH/modules.load $PRIVATE_MODULE_DIR/
cp $TEMP_MODULES_PATH/modules.dep $PRIVATE_MODULE_DIR/
cp $TEMP_MODULES_PATH/modules.softdep $PRIVATE_MODULE_DIR/

echo "==========================================="
echo "making ramdisk..."
mkbootfs -d ./system ./ramdisk | minigzip > out/ramdisk.img
echo "make ramdisk done."

echo "==========================================="
echo "making boot image..."
mkbootimg  --kernel $KERNEL_IMAGE --ramdisk out/ramdisk.img --dtb $DTB_PATH --cmdline "console=ttyFIQ0 androidboot.baseband=N/A androidboot.wificountrycode=US androidboot.veritymode=enforcing androidboot.hardware=rk30board androidboot.console=ttyFIQ0 androidboot.verifiedbootstate=orange firmware_class.path=/vendor/etc/firmware init=/init rootwait ro loop.max_part=7 androidboot.first_stage_console=1 androidboot.selinux=permissive buildvariant=userdebug" --os_version 11 --os_patch_level 2020-06-05 --second ../kernel/resource.img --header_version 2 --output out/boot.img 
echo "make boot image done."
echo "==========================================="
