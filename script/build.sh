#!/usr/bin/env bash

version="v0.4.1"

# -------------------------------------------------------- #
# PROXMOX Template Builder
# - a tool to build proxmox VM templates, based on *.img
#
#  author: Gabriel Martins, aka GabTec
#    date: 2024-04-06
#
#  Parameters:
#   -b <bridge>     - define the network bridge for the template vm (defaults to vmbr0)
#   -c <cpu_count>  - define the number of cpus for the template vm (defaults to 1)
#   -d <distro>     - define the base ubuntu distro version for the template vm (defaults to 22.04)
#   -i <vm_id>      - define a custom id for the template vm (defaults to 9000)
#   -m <mem_in_mib> - define the memory value for the template vm (defaults to 1024)
#   -s <storage>    - define the destination storage pool for the template vm (defaults to local-lvm)
#   -S <disk_inc>   - define the disk increment on top of base size (defaults to 2.2G + 2G)
#  Example:
#  - ./build.sh -d 22.04 9000
#
#  WIP:
#  - add more cli arguments
# -------------------------------------------------------- #
cat << EOF
 ____
|  _ \ _ __ _____  ___ __ ___   _____  __
| |_) | '__/ _ \ \/ / '_ \` _ \ / _ \ \/ /
|  __/| | | (_) >  <| | | | | | (_) >  <
|_|   |_|  \___/_/\_\_| |_| |_|\___/_/\_\\ template builder
                                                ${version}
--------- created by GabTec, 2024 (c) ---------------------

EOF

# IMPORTS
source /dev/stdin  <<< "$(curl -s https://raw.githubusercontent.com/gabtec/shell-h/main/lib/helpers.sh)"

# UTILS
function getUbuntuCodename() {
    VERSION=$1

    case "$VERSION" in
        "24.04" ) echo "noble" ;;
        "22.04" ) echo "jammy" ;;
        "20.04" ) echo "focal" ;;
        "18.04" ) echo "bionic" ;;
        "16.04" ) echo "xenial" ;;
        "14.04" ) echo "trusty" ;;
    esac

    return 0
}

# VARIABLES
VM_ID=9000 # default, will be override
VM_USER="ubuntu"
VM_PASS="ubuntu"
VM_VSWITCH="vmbr0"
VM_CPU=1
VM_MEM=1024
VM_STORAGE_POOL="local-lvm"
VM_TAGS="base template"
VM_DISK_INCREASE="+2G" # base disk has 2.2G
NODE_NAME=$(hostname)

IMG_DISTRO="ubuntu" # For now is the only distro supported
IMG_VERSION="22.04"

IMG_CODENAME=$(getUbuntuCodename $IMG_VERSION)
IMG_NAME="${IMG_CODENAME}-server-cloudimg-amd64.img"
IMG_URL="https://cloud-images.ubuntu.com/${IMG_CODENAME}/current/${IMG_NAME}"
IMG_TAG=$(date +"%Y%m%d%H%M%S")
TPL_NAME="$IMG_DISTRO-$IMG_VERSION-$IMG_TAG"
TPL_DISK_NAME="${VM_STORAGE_POOL}:vm-${VM_ID}-disk-0"
TPL_CLOUDINIT_DISK_NAME="$VM_STORAGE_POOL:cloudinit"

# FUNCTIONS
function show_usage() {
    echo "usage: $0 [options...]"
    echo " -b VSWITCH name (default: vmbr0)" 
    echo " -c CPU count (default: 1)" 
    echo " -d Distro version/code (default: 22.04)" 
    echo " -i VM ID for the final template (default: 9000)" 
    echo " -m MEM allocation in MiB (default: 1024)" 
    echo " -s Storage Pool Name (default: local-lvm)"
    echo " -S Storage Increase (default: +2G)"
    echo " -h Show help/usage and quit" 
    echo " -v Show version number and quit" 

    exit 0
}

function show_version() {
    echo "Version: $0 $version"
    exit 0
}

function set_bridge(){
    VM_VSWITCH=$1
}

function set_cpu(){
    VM_CPU=$1
}

function set_distro() {
    IMG_VERSION=$1
}

function set_id(){
    VM_ID=$1
}

function set_mem(){
    VM_MEM=$1
}

function set_storage(){
    VM_STORAGE_POOL=$1
}

function set_storage_increase(){
    VM_DISK_INCREASE=$1
}


# PARSE ARGS
OPTSTRING="b:c:d:i:m:s:S:hv"
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    b)
    #   echo "Option -c [CPU ] was triggered, Argument: ${OPTARG}"
      set_bridge $OPTARG
      ;;
    c)
    #   echo "Option -c [CPU ] was triggered, Argument: ${OPTARG}"
      set_cpu $OPTARG
      ;;
    d)
    #   echo "Option -c [CPU ] was triggered, Argument: ${OPTARG}"
      set_distro $OPTARG
      ;;
    i)
    #   echo "Option -i [id] was triggered, Argument: ${OPTARG}"
      set_id $OPTARG
      ;;
    m)
    #   echo "Option -m [MEM] was triggered, Argument: ${OPTARG}"
      set_mem $OPTARG
      ;;
    s)
    #   echo "Option -s [STORAGE] was triggered, Argument: ${OPTARG}"
      set_storage $OPTARG
      ;;
    S)
    #   echo "Option -s [STORAGE] was triggered, Argument: ${OPTARG}"
      set_storage_increase $OPTARG
      ;;
    v)
      show_version
      ;;
    h)
      show_usage
      ;;
    ?)
        show_usage
    #   echo "Invalid option: -${OPTARG}."
    #   exit 1
      ;;
  esac
done
# if [ "$1" == "-h" ] || [ "$1" == "--help" ];then 
#     show_usage
# fi
# if [ "$1" == "-v" ] || [ "$1" == "--version" ];then 
#     show_version
# fi
# if [ "$#" -eq 0 ];then 
#     log info "Using default VM_ID=$VM_ID"
# else
#     # last value in args array
#     VM_ID="${@:$#}" 
#     TPL_DISK_NAME="${VM_STORAGE_POOL}:vm-${VM_ID}-disk-0"
#     log info "Using VM_ID=$VM_ID"
# fi

echo SELECTED OPTIONS:
echo "-----------------"
echo "VMID -----------> $VM_ID"
echo "NETWORK BRIDGE -> $VM_VSWITCH"
echo "NUM CPUs -------> $VM_CPU"
echo "MEMORY ---------> $VM_MEM"
echo "DISTRO ---------> $IMG_DISTRO $IMG_VERSION"
echo "STORAGE POOL ---> $VM_STORAGE_POOL"
echo "DISK SIZE ------> 2.2G $VM_DISK_INCREASE"
echo ""

read -p "[  INFO ]: Do you wish to continue? (y/N)" ANSWER
if [ "$ANSWER" != "y" ];then 
    log warn "You choose to cancel. Exiting..."
    exit 2
fi

log ok "Lets proceed..."
# MAIN
log info "Check for ${IMG_DISTRO} image..."

if [ -f "$IMG_NAME" ];then
    log ok "Image already exists."
    log info "Skipping download."
else
    log info "Downloading image..."
    wget $IMG_URL
fi

# check if tools are installed
HAS_REQS=$(which virt-customize)
if [ "$?" -eq 0 ];then
    log ok "Found virt-customize already installed."
else
    log info "virt-customize NOT found."
    log info "virt-customize will be installed."
    # install kvm tools, e.g. virt-customize
    apt install libguestfs-tools -y
fi

# installs quemu-agent and re-pack image again
log info "Installing qemu-agent"

# cloud-init can sometime hang and this disables it during bootup
# if so, try: virt-customize --add $IMG_NAME --install qemu-guest-agent --run-command "systemctl mask cloud-init.service" 
virt-customize --add $IMG_NAME --install qemu-guest-agent --run-command "systemctl enable qemu-guest-agent && systemctl start qemu-guest-agent"
# this will show a warning: virt-customize: warning: random seed could not be set for this type of guest
# but its a bug ?? -- https://bugzilla.redhat.com/show_bug.cgi?id=1677859

log info "Creating virtual machine..."

qm create $VM_ID \
--name $TPL_NAME \
--ostype l26 \
--cpu cputype=host \
--cores $VM_CPU \
--sockets 1 \
--memory $VM_MEM \
--net0 virtio,bridge=$VM_VSWITCH

log info "Importing disk to proxmox vm"
qm importdisk $VM_ID $IMG_NAME $VM_STORAGE_POOL
qm set $VM_ID --scsihw virtio-scsi-single --scsi0 $TPL_DISK_NAME

qm set $VM_ID --ide2 $TPL_CLOUDINIT_DISK_NAME
qm set $VM_ID --boot c --bootdisk scsi0

qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --agent enabled=1
#   qm set $1 --agent enabled=1,fstrim_cloned_disks=1

# initial disk has 2.2GB, this will increase it by x GB
qm disk resize $VM_ID scsi0 $VM_DISK_INCREASE

qm set $VM_ID --ipconfig0 "ip=dhcp,ip6=auto"
# set default cloud-init user
qm set $VM_ID --ciuser $VM_USER
# set default cloud-init password
qm set $VM_ID --cipassword $VM_PASS

qm template $VM_ID

# add notes
DESC=$(echo -e "# $TPL_NAME \n - created with qemu cli \n - to be deployed with terraform to change vm settings \n - default user/passw = $VM_USER/$VM_PASS \n - disk size 2.2G $VM_DISK_INCREASE")

pvesh set nodes/${NODE_NAME}/qemu/${VM_ID}/config --description "$DESC"
pvesh set nodes/${NODE_NAME}/qemu/${VM_ID}/config --tags "$VM_TAGS"

if [ "$?" -eq 0 ];then
    log ok "Template successfully created"
    exit 0
else 
    log error "Template NOT created!"
    exit 1
fi