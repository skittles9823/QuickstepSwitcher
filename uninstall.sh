MAGISK_VER_CODE=`grep MAGISK_VER_CODE /data/adb/magisk/util_functions.sh`
imageless_magisk() {
  [ $MAGISK_VER_CODE -gt 18100 ]
  return $?
}

if imageless_magisk; then
  MODDIR=/data/adb/modules/quickstepswitcher
else
  MODDIR=/sbin/.magisk/img/quickstepswitcher
fi

DID_MOUNT_RW=
is_mounted() {
  grep " `readlink -f $1` " /proc/mounts 2>/dev/null
  return $?
}

is_mounted_rw() {
  grep " `readlink -f $1` " /proc/mounts | grep " rw," 2>/dev/null
  return $?
}

mount_rw() {
  mount -o remount,rw $1
  DID_MOUNT_RW=$1
}

unmount_rw() {
  if [ "x$DID_MOUNT_RW" = "x$1" ]; then
    mount -o remount,ro $1
  fi
}

SWITCHER_DIR=/data/user_de/0/xyz.paphonb.quickstepswitcher
SWITCHER_OUTPUT=$SWITCHER_DIR/files

# Assign $STEPDIR var
if [ -d "/product/overlay" ]; then
  PRODUCT=true
  # Yay, magisk supports bind mounting /product now
  MAGISK_VER_CODE=$(grep "MAGISK_VER_CODE=" /data/adb/magisk/util_functions.sh | awk -F = '{ print $2 }')
  if [ $MAGISK_VER_CODE -ge "19308" ]; then
    MOUNTPRODUCT=
    STEPDIR=$MODDIR/system/product/overlay
  else
    MOUNTPRODUCT=true
    STEPDIR=/product/overlay
    is_mounted " /product" || mount /product
    is_mounted_rw " /product" || mount_rw /product
  fi
elif [ -d /oem/OP ];then
  OEM=true
  is_mounted " /oem" || mount /oem
  is_mounted_rw " /oem" || mount_rw /oem
  is_mounted " /oem/OP" || mount /oem/OP
  is_mounted_rw " /oem/OP" || mount_rw /oem/OP
  STEPDIR=/oem/OP/OPEN_US/overlay/framework
else
  PRODUCT=; OEM=; MOUNTPRODUCT=
  STEPDIR=$MODDIR/system/vendor/overlay
fi
if [ "$MOUNTPRODUCT" ]; then
  is_mounted " /product" || mount /product
  is_mounted_rw " /product" || mount_rw /product
elif [ "$OEM" ];then
  is_mounted " /oem" || mount /oem
  is_mounted_rw " /oem" || mount_rw /oem
  is_mounted " /oem/OP" || mount /oem/OP
  is_mounted_rw " /oem/OP" || mount_rw /oem/OP
fi

rm -rf $STEPDIR/QuickstepSwitcherOverlay.apk

if [ "$STEPDIR" == "/product/overlay" ]; then
  unmount_rw /product
elif [ "$STEPDIR" == "/oem/OP/OPEN_US/overlay/framework" ]; then
  unmount_rw /oem/OP
  unmount_rw /oem
fi

rm -rf /data/resource-cache/*
find /data/resource-cache/ -name *QuickstepSwitcherOverlay* -exec rm -rf {} \;
rm -f /data/adb/post-fs-data.d/quickswitch-post.sh
