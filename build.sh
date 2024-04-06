#!/usr/bin/env bash

version="v0.2.0"

# -------------------------------------------------------- #
# PROXMOX Template Builder
# - a tool to build proxmox VM templates, based on *.img
#
#  author: Gabriel Martins, aka GabTec
#    date: 2024-04-06
#
#  Parameters:
#   - { number } - vmID - the id for the template vm
#                       - defaults to 9000
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

# FUNCTIONS
function show_usage() {
    echo "usage: $0 [options...] <vm_id>"
    echo " -d, --distro-version Distro version/code (default: 22.04)" 
    echo " -s, --storage-pool   Destiny Storage Pool Name (default: local-lvm)" 
    echo " -h, --help           Show help/usage and quit" 
    echo " -v, --version        Show version number and quit" 

    exit 0
}

function show_version() {
    echo "Version: $0 $version"
    exit 0
}

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
VM_ID=9000
VM_USER="ubuntu"
VM_PASS="ubuntu"
VM_STORAGE_POOL="local-lvm"
NODE_NAME=$(hostname)

IMG_DISTRO="ubuntu" # For now is the only distro supported
IMG_VERSION="22.04"

IMG_CODENAME=$(getUbuntuCodename "22.04")
IMG_NAME="${IMG_CODENAME}-server-cloudimg-amd64.img"
IMG_URL="https://cloud-images.ubuntu.com/${IMG_CODENAME}/current/${IMG_NAME}"
IMG_TAG=$(date +"%Y%m%d%H%M%S")
TPL_NAME="$IMG_DISTRO-$IMG_VERSION-$IMG_TAG"
TPL_DISK_NAME="${VM_STORAGE_POOL}:vm-${VM_ID}-disk-0"
TPL_CLOUDINIT_DISK_NAME="$VM_STORAGE_POOL:cloudinit"

# PARSE ARGS
if [ "$1" == "-h" ] || [ "$1" == "--help" ];then 
    show_usage
fi
if [ "$1" == "-v" ] || [ "$1" == "--version" ];then 
    show_version
fi
if [ "$#" -eq 0 ];then 
    log info "Using default VM_ID=$VM_ID"
else
    # last value in args array
    VM_ID="${@:$#}" 
    TPL_DISK_NAME="${VM_STORAGE_POOL}:vm-${VM_ID}-disk-0"
    log info "Using VM_ID=$VM_ID"
fi

read -p "[  INFO ]: Do you wish to continue? (y/N)" ANSWER
if [ "$ANSWER" != "y" ];then 
    log warn "You choose to cancel. Exiting..."
    exit 2
fi

log ok "Lets proceed..."

# MAIN
set -e

log info "Check for ${IMG_DISTRO} image..."
# TODO: validate image exists
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

# instala o quemu-agent e volta a empacotar a imagem
log info "Installing qemu-agent"

# virt-customize --add $IMG_NAME --install qemu-guest-agent
# virt-customize --add $IMG_NAME --install qemu-guest-agent --run-command "systemctl mask cloud-init.service" #cloud-init can sometime hang and this disables it during bootup
virt-customize --add $IMG_NAME --install qemu-guest-agent --run-command "systemctl enable qemu-guest-agent && systemctl start qemu-guest-agent"

# will show a warning: virt-customize: warning: random seed could not be set for this type of guest
# but its a bug ?? -- https://bugzilla.redhat.com/show_bug.cgi?id=1677859

log info "Creating virtual machine..."

qm create $VM_ID \
--name $TPL_NAME \
--ostype l26 \
--cpu cputype=host \
--cores 2 \
--sockets 1 \
--memory 1024 \
--net0 virtio,bridge=vmbr0

log info "Importing disk to proxmox vm"
qm importdisk $VM_ID $IMG_NAME $VM_STORAGE_POOL
qm set $VM_ID --scsihw virtio-scsi-single --scsi0 $TPL_DISK_NAME

qm set $VM_ID --ide2 $TPL_CLOUDINIT_DISK_NAME
qm set $VM_ID --boot c --bootdisk scsi0

qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --agent enabled=1
#   qm set $1 --agent enabled=1,fstrim_cloned_disks=1

# disco initial tem 2GB, agora somo mais 2
# qm disk resize $VM_ID scsi0 +2G
qm set $VM_ID --ipconfig0 "ip=dhcp,ip6=auto"
# set default cloud-init user
qm set $VM_ID --ciuser $VM_USER
# set default cloud-init password
qm set $VM_ID --cipassword $VM_PASS

qm template $VM_ID

# add notes
DESC=$(echo -e "# $TPL_NAME \n - created with qemu cli \n - to be deployed with terraform to change vm settings \n - default user/passw = $VM_USER/$VM_PASS")

pvesh set nodes/${NODE_NAME}/qemu/${VM_ID}/config --description "$DESC"

if [ "$?" -eq 0 ];then
    log ok "Template successfully created"
    exit 0
else 
    log error "Template NOT created!"
    exit 1
fi