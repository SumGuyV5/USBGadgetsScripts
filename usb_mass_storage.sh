#!/bin/bash -e
if [ `whoami` != root ]
then 
  echo "Please run as root."
  exit
fi

set -e

CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"
VID="0x0525"
PID="0xa4a2"
SERIAL="0123456789"
MANUF="Myself"
PRODUCT="MyProduct"
NUM="g1"

IMG="/root/lum0.img"

case "$1" in
    start)
        echo "Creating the USB gadget"
        echo "Loading composite module"
        modprobe libcomposite

        echo "Creating gadget directory g1"
        mkdir -p $GADGET/$NUM

        cd $GADGET/$NUM
        if [ $? -ne 0 ]; then
            echo "Error creating usb gadget in configfs"
            exit 1;
        else
            echo "OK"
        fi

        echo "Creating Mass Storage interface"
        echo "\tCreating backing file"
        dd if=/dev/zero of=$IMG bs=1024 count=1024 > /dev/null 2>&1
        mkdosfs $IMG > /dev/null 2>&1
        echo "\tOK"

        echo "\tCreating gadget functionality"
        mkdir functions/mass_storage.0
        echo 1 > functions/mass_storage.0/stall
        echo $IMG > functions/mass_storage.0/lun.0/file
        echo 1 > functions/mass_storage.0/lun.0/removable
        echo 0 > functions/mass_storage.0/lun.0/cdrom
        mkdir configs/c.1
        mkdir configs/c.1/strings/0x409
        ln -s functions/mass_storage.0 configs/c.1
        echo "\tOK"
        echo "OK"

#        echo "Setting Vendor and Product ID's"
#        echo $VID > idVendor
#        echo $PID > idProduct
#        echo "OK"
#
#        echo "Setting English strings"
#        mkdir -p strings/0x409
#        echo $SERIAL > strings/0x409/serialnumber
#        echo $MANUF > strings/0x409/manufacturer
#        echo $PRODUCT > strings/0x409/product
#        echo "OK"

        echo "Binding USB Device Controller"
        #echo `ls /sys/class/udc` > UDC
        echo "OK"
        ;;
    stop)
        echo "Stopping the USB gadget"

        cd $GADGET/$NUM

        if [ $? -ne 0 ]; then
            echo "Error: no configfs gadget found" 
            exit 1;
        fi

        echo "Unbinding USB Device Controller"
        echo "" > UDC
        echo "OK"

        echo "Removing Mass Storage interface"
        rm -f configs/c.1/mass_storage.0
        rm -f $IMG
        rmdir functions/mass_storage.0
        echo "OK"

        echo "Clearing English strings"
        rmdir strings/0x409
        echo "OK"

        echo "Cleaning up configuration"
        rmdir configs/c.1/strings/0x409
        rmdir configs/c.1
        echo "OK"

        echo "Removing gadget directory"
        cd $GADGET
        rmdir $NUM
        cd /
        echo "OK"

        echo "Disable composite USB gadgets"
        modprobe -r libcomposite
        echo "OK"
        ;;
    *)
        echo "Usage : $0 {start|stop}"
esac