# ------------------------------------------------ #
#   Packer Plugins to install
# ------------------------------------------------ #
packer {
  required_plugins {
    name = {
      version = "~> 1.1.7"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# ------------------------------------------------ #
#   Variables Definition
# ------------------------------------------------ #
locals {
  # connection to proxmox host
  proxmox_node_ip    = "192.168.1.1"
  proxmox_node_name  = "pve"
  proxmox_root_name  = "root@pam"  # change me
  proxmox_root_passw = "xxxxxxxxx" # change me
  proxmox_vswitch    = "vmbr0"
  # template definitions
  template_src_vmid   = 7000
  template_final_vmid = 7001
  template_final_name = "ubuntu-22.04-pkr-docker-202405010000"
  template_tags       = "ubuntu;template;packer;docker"
  # ATENTION: line 118 hardcoded ubuntu code name "jammy"
}

# ------------------------------------------------ #
#   Proxmox-Builder Config
# ------------------------------------------------ #
source "proxmox-clone" "ubuntu" {
  # ------------ server access ------------------
  # COMMENT this credentials, if using env vars
  proxmox_url              = "https://${local.proxmox_node_ip}:8006/api2/json"
  node                     = local.proxmox_node_name                           # Where packer will spin up the VM
  password                 = local.proxmox_root_passw                          # OneOf: password or token
  username                 = local.proxmox_root_name                           # OR "user@pve!tokenid" if using tokens
  insecure_skip_tls_verify = true                                              # Skip validating the server self sign certificate.

  clone_vm_id = local.template_src_vmid # or use clone_vm instead
  vm_id       = local.template_final_vmid # the id for the final template VM

  cores           = 1
  memory          = 1024
  qemu_agent      = true # required for packer provisioner to work
  full_clone      = true
  cpu_type        = "host"
  os              = "l26" # this means linux
  scsi_controller = "virtio-scsi-single"

  cloud_init              = true        # to add a cloud-init disk, even if src img has one it doens't keep it
  cloud_init_storage_pool = "local-lvm" # required if cloud_init=true

  network_adapters {
    bridge = local.proxmox_vswitch
    model  = "virtio"
  }

  // SOS
  # rng0 {
  #   source    = "/dev/urandom"
  #   max_bytes = 1024
  #   period    = 1000
  # }

  template_description = "# Ubuntu Server + Docker \n - image made with packer from cloud-init image \n - installed packages: qemu-guest-agent, docker \n - disk size 4.2G"
  template_name        = local.template_final_name # random if not set
  tags                 = local.template_tags

  # this is for ssh connection
  ssh_username = "root" # or any other name
  ssh_timeout = "10m"
}
# ------------------------------------------------ #
#   Build
# ------------------------------------------------ #
build {
  name    = "build step" # SOS
  sources = ["source.proxmox-clone.ubuntu"]

  # read: https://ubuntu.com/tutorials/how-to-build-your-own-ami-from-ubuntu-pro-using-packer#5-defining-the-provisioner-component
  provisioner "shell" {
    inline = [
      # DEBUG TIP: in case of failure check if base template disk size has enought space for the packages to install
      "echo Provisioning required packages...",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 3; done",
      # "cloud-init status --wait",
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get update && sudo apt-get upgrade -y -q",
      "sudo apt-get install ca-certificates curl -y -q",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "sudo echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y -q",
      "echo '[ INFO ]: Docker installed.' ",
      "echo '[ INFO ]: Checking version:' ",
      "sudo docker version"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo cloud-init clean --machine-id"
    ]
  }
}