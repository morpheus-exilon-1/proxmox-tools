#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Input for old and new VM IDs
read -p "Enter the current VM ID: " old_vm_id
read -p "Enter the new VM ID: " new_vm_id

# Paths
config_path="/etc/pve/qemu-server"

# Backup the original configuration
config_file="${config_path}/${old_vm_id}.conf"
if [ -f "$config_file" ]; then
    cp "$config_file" "${config_file}.backup"
else
    echo "Error: Configuration file for VM ID ${old_vm_id} does not exist."
    exit 1
fi

# Check if new VM ID already exists
if [ -f "${config_path}/${new_vm_id}.conf" ]; then
    echo "Error: A VM with the new ID already exists."
    exit 1
fi

# Rename the configuration file
mv "$config_file" "${config_path}/${new_vm_id}.conf"

# Search and rename VM disks in all Volume Groups
disk_count=0
lvm_vg_list=$(vgs --noheadings -o vg_name)

for vg in $lvm_vg_list; do
    lvm_path="/dev/$vg"
    for file in $(lvs --noheadings -o lv_name $vg | grep "vm-${old_vm_id}-disk-"); do
        if [ -e "${lvm_path}/${file}" ]; then
            new_file="$(echo $file | sed "s/vm-${old_vm_id}-disk/vm-${new_vm_id}-disk/")"
            lvrename $vg $file $new_file
            # Update the config file with the new disk name
            sed -i "s|${vg}/${file}|${vg}/${new_file}|g" "${config_path}/${new_vm_id}.conf"
            ((disk_count++))
            if [ $disk_count -ge 5 ]; then
                break
            fi
        fi
    done
done

# Update the VM configuration file references from the old VM ID to the new VM ID
sed -i "s/vm-${old_vm_id}/vm-${new_vm_id}/g" "${config_path}/${new_vm_id}.conf"

echo "VM ID has been changed from ${old_vm_id} to ${new_vm_id}."
