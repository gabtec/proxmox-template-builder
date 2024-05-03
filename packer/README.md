# Create Proxmox VM Template using Packer

## Prep Step

First create a VM template from an oficial ubuntu cloud image.

**NOTE:** this image MUST have qemu-guest-agent installed [explanation](https://aaronsplace.co.uk/blog/2021-08-07-packer-proxmox-clone.html)

Use the included [build.sh script](../README.md), inside your proxmox host:

> wget https://raw.githubusercontent.com/gabtec/proxmox-template-builder/main/script/build.sh

## Packer install

On you local desktop, install packer [read official docs here](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)

```sh
# macOS example
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

## Run Packer Build

After having the base template image ready on your proxmox host, clone this [ubuntu folder](./ubuntu-22.04/ubuntu.pkr.hcl) that contains an hcl file with packer example code.

Review it, and update the file **local variables block**, mainly the credentials to allow access to your proxmox host.

Also update the **provisioner block** to include/install any package that you need.
The provided file, created a new Vm template with docker installed. You can choose other packages.

Then run:

```sh
# fmt to format packer code (optional)
packer fmt .

# init to download packer dependencies
packer init .

# validate to check if code is executable
packer validate .

# build to start building the template
packer build .

# optionaly, run build with some kind of debug
packer build -debug .
packer build -on-error=ask .
```

## Next

Now that you have a VM template, you can deploy new VM's, using:

- template clone
- terraform or other IaC tool

### Some articles that help me with this

- https://ronamosa.io/docs/engineer/LAB/proxmox-packer-vm/
- https://github.com/dustinrue/proxmox-packer/blob/main/ubuntu2204/packer.pkr.hcl
