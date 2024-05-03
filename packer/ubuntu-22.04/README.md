# Create Proxmox VM Template using Packer

## Prep Step

First create a VM template from an oficial ubuntu cloud image.
**NOTE:** this image MUST have qemu-guest-agent installed [doc](https://aaronsplace.co.uk/blog/2021-08-07-packer-proxmox-clone.html)

Use this script [proxmox-template-builder](https://github.com/gabtec/proxmox-template-builder), inside your proxmox host:

> wget https://raw.githubusercontent.com/gabtec/proxmox-template-builder/v0.1.0/build.sh

And check repo docs [Proxmox Template Builder](https://github.com/gabtec/proxmox-template-builder.git)

## Packer install

```sh
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

## Run

After having the base template image ready on your proxmox host,
review this [ubuntu.pkr.hcl](./ubuntu.pkr.hcl) file **local variables**, and then run:

```sh
packer init .
packer fmt .
packer validate .
packer build .
# optionaly
packer build -debug .
packer build -on-error=ask .
```

## Next

- Deploy new VM's from the new template using terraform

See https://ronamosa.io/docs/engineer/LAB/proxmox-packer-vm/
See https://github.com/dustinrue/proxmox-packer/blob/main/ubuntu2204/packer.pkr.hcl
