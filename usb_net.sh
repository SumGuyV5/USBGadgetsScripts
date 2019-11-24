#!/bin/bash -e

CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"
VID="0x0525"
PID="0xa4a2"
SERIAL="0123456789"
MANUF="Myself"
PRODUCT="MyProduct"
NUM="g3"

case "$1" in
    start)
        echo "Creating the USB gadget"
        echo "Loading composite module"
        modprobe libcomposite

        echo "Creating gadget directory g2"
        mkdir -p $GADGET/$NUM

        cd $GADGET/$NUM
        if [ $? -ne 0 ]; then
            echo "Error creating usb gadget in configfs"
            exit 1;
        else
            echo "OK"
        fi
        
        echo "Creating Net interface"

        echo "\tCreating gadget functionality"
        mkdir -p functions/rndis.usb0  # network
        mkdir -p configs/c.1
        echo 250 > configs/c.1/MaxPower
        ln -s functions/rndis.usb0 configs/c.1/
        echo "\tOK"
        echo "OK"

        echo "Setting Vendor and Product ID's"
        echo 0x1d6b > idVendor  # Linux Foundation
        echo 0x0104 > idProduct # Multifunction Composite Gadget
        echo 0x0100 > bcdDevice # v1.0.0
        echo 0x0200 > bcdUSB    # USB 2.0

        echo 0xEF > bDeviceClass
        echo 0x02 > bDeviceSubClass
        echo 0x01 > bDeviceProtocol
        echo "OK"

        echo "Setting English strings"
        mkdir -p strings/0x409
        echo "deadbeef00115599" > strings/0x409/serialnumber
        echo "irq5 labs"        > strings/0x409/manufacturer
        echo "Pi Zero Gadget"   > strings/0x409/product
        echo "OK"
        
        # OS descriptors
        echo "Setting OS descriptors"
        echo 1       > os_desc/use
        echo 0xcd    > os_desc/b_vendor_code
        echo MSFT100 > os_desc/qw_sign
        
        echo RNDIS   > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
        echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
        
        ln -s configs/c.1 os_desc
        echo "OK"

        echo "Binding USB Device Controller"
        echo `ls /sys/class/udc` > UDC
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

        echo "Removing Serial interface"
        rm -f configs/c.1
        rmdir functions/rndis.usb0
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