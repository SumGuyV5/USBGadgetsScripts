#!/bin/bash -e
if [ `whoami` != root ]
then 
  echo "Please run as root."
  exit
fi

rmmod g_mass_storage
rmmod g_ether

echo "0" >/sys/bus/platform/devices/sunxi_usb_udc/otg_role

modprobe g_mass_storage file=/root/lun0.img stall=0 removable=y idVendor=0x0951 idProduct=0x1666 iSerialNumber=79BABF7158041372 iManufacturer=Myself iProduct=VirtualBlockDevice

echo "2" >/sys/bus/platform/devices/sunxi_usb_udc/otg_role
