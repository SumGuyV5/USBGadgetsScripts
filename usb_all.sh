#!/bin/bash -e
if [ `whoami` != root ]
then 
  echo "Please run as root."
  exit
fi

CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"
VID="0x0526"
PID="0xa4a3"
SERIAL="0123456789"
MANUF="Myself"
PRODUCT="MyProduct"
N="usb0"

IMG="/root/lum0.img"

Start_Mass()
{
  echo "Creating Mass Storage interface"
  echo "\tCreating backing file"
  dd if=/dev/zero of=$IMG bs=1024 count=1024 > /dev/null 2>&1
  mkdosfs $IMG > /dev/null 2>&1
  echo "\tOK"

  echo "\tCreating gadget functionality"
  mkdir -p functions/mass_storage.$N
  echo 1 > functions/mass_storage.$N/stall
  echo $IMG > functions/mass_storage.$N/lun.0/file
  echo 1 > functions/mass_storage.$N/lun.0/removable
  echo 0 > functions/mass_storage.$N/lun.0/cdrom
  ln -s functions/mass_storage.$N configs/c.1
  echo "\tOK"
  echo "OK"

}

Start_Serial()
{
  mkdir -p functions/acm.$N    # serial
  
  mkdir -p configs/c.1
  
  ln -s functions/acm.$N   configs/c.1/
}

Start_Net()
{
  mkdir -p functions/rndis.$N  # network

  ln -s functions/rndis.$N configs/c.1/
  
  # OS descriptors
  echo 1       > os_desc/use
  echo 0xcd    > os_desc/b_vendor_code
  echo MSFT100 > os_desc/qw_sign

  echo RNDIS   > functions/rndis.$N/os_desc/interface.rndis/compatible_id
  echo 5162001 > functions/rndis.$N/os_desc/interface.rndis/sub_compatible_id

  ln -s configs/c.1 os_desc
  
  udevadm settle -t 5 || :
}

HID_Keyboard()
{
  mkdir -p functions/hid.0
  echo 1 > functions/hid.0/protocol # Keyboard
  echo 1 > functions/hid.0/subclass # Boot Interface Subclass
  echo 8 > functions/hid.0/report_length
  echo -ne \\x05\\x01\\x09\\x06\\xA1\\x01\\x05\\x07\\x19\\xE0\\x29`
  	`\\xE7\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02`
  	`\\x95\\x01\\x75\\x08\\x81\\x01\\x95\\x05\\x75\\x01\\x05`
  	`\\x08\\x19\\x01\\x29\\x05\\x91\\x02\\x95\\x01\\x75\\x03`
  	`\\x91\\x01\\x95\\x06\\x75\\x08\\x15\\x00\\x25\\x65\\x05`
  	`\\x07\\x19\\x00\\x29\\x65\\x81\\x00\\xC0 > functions/hid.0/report_desc
  ln -s functions/hid.0 configs/c.1/
}

HID_Mouse()
{
  mkdir -p functions/hid.1
  echo 2 > functions/hid.1/protocol # Mouse
  echo 1 > functions/hid.1/subclass # Boot Interface Subclass
  echo 8 > functions/hid.1/report_length
  echo -ne \\x05\\x01\\x09\\x02\\xA1\\x01\\x09\\x01\\xA1\\x00\\x05`
  	`\\x09\\x19\\x01\\x29\\x03\\x15\\x00\\x25\\x01\\x95\\x03`
  	`\\x75\\x01\\x81\\x02\\x95\\x01\\x75\\x05\\x81\\x01\\x05`
  	`\\x01\\x09\\x30\\x09\\x31\\x15\\x81\\x25\\x7F\\x75\\x08`
  	`\\x95\\x02\\x81\\x06\\xC0\\xC0 > functions/hid.1/report_desc
  ln -s functions/hid.1 configs/c.1/
}

case "$1" in
    start)
        echo "Creating the USB gadget"
        echo "Loading composite module"
        modprobe libcomposite

        echo "Creating gadget directory g1"
        mkdir -p $GADGET/g1

        cd $GADGET/g1
        if [ $? -ne 0 ]; then
            echo "Error creating usb gadget in configfs"
            exit 1;
        else
            echo "OK"
        fi
        mkdir -p configs/c.1

        #Start_Mass
        
        #Start_Serial
        
        #Start_Net
        
        HID_Keyboard
        
        HID_Mouse

        echo "Setting Vendor and Product ID's"
        echo $VID > idVendor
        echo $PID > idProduct
        echo "OK"

        echo "Setting English strings"
        mkdir -p strings/0x409
        echo $SERIAL > strings/0x409/serialnumber
        echo $MANUF > strings/0x409/manufacturer
        echo $PRODUCT > strings/0x409/product
        echo "OK"
                
        echo 250 > configs/c.1/MaxPower

        echo "Binding USB Device Controller"
        ls /sys/class/udc > UDC
        echo "OK"
        ;;
    stop)
        echo "Stopping the USB gadget"
        
        cd $GADGET/g1
        echo '' > UDC
        find configs -type l -exec rm -v {} \;
        #rmdir configs/c.1/strings/0x409
        find configs -name 'strings' -exec rmdir -v {}/0x409 \;
        #rmdir configs/c.1
        ls -d configs/* | xargs rmdir -v
        #rmdir strings/0x409
        ls -d strings/* | xargs rmdir -v
        #rmdir functions/hid.usb0
        ls -d functions/* | xargs rmdir -v
        
        cd ..
        rmdir -v g1
        ;;
    *)
        echo "Usage : $0 {start|stop}"
esac