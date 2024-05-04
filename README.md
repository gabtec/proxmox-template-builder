# proxmox-template-builder

:rocket: Proxmox template builder tools

This is a two step process, to build proxmox virtual machine templates.

## Step 1 - qemu script

Inside [./script](./script/) folder there is a [build.sh](./script/build.sh) script.

It is a very opinionated script, that aims to bring simplification.

The script MUST be executed inside proxmox host.

It will download an oficial Ubuntu cloud image and create a Proxmox Template VM from it. In the process it will add **qemu-guest-agent** package to it.

After you've created the **Base Template Image**, you can:

- clone it and create new VM's from proxmox dashboard
- deploy new VM's using terraform, and referencing this image as the source template
- extend it, by installing new packages and generate a new template, using the **Step 2** Packer code

To keep this simple:

- the only supported distro is **Ubuntu Server**, for now
- the network interface will be attached to **vmbr0**
- the template will have 1 cpu and 1024MiB of memory
- if you like, you can edit the script and change some of this values (using terraform you will also be able to specify new values)

What you can choose:

- the distro version (e.g. 20.04, 22.04, etc)
- the template VM ID (defaults to 9000)

## Usage

SSH into your proxmox server, and run:

```sh
# download
wget https://raw.githubusercontent.com/gabtec/proxmox-template-builder/v0.4.0/script/build.sh
chmod +x build.sh

# run, using all defaults
./build.sh

# run, setting all options
 ./build.sh -b vmbr1 -c 4 -m 2048 -i 7777 -d 18.04 -s some-lvm -S +6G

# show version
./build.sh -v

# show help
./build.sh -h

usage: ./build.sh [options...]
  -b,   VSWITCH name (default: vmbr0)
  -c,   CPU count (default: 1)
  -d,   Distro version/code (default: 22.04)
  -i,   VM ID for the final template (default: 9000)
  -m,   MEM allocation in MiB (default: 1024)
  -s,   Storage Pool Name (default: local-lvm)
  -S,   Storage Increase (default: +2G)

  -h,   Show help/usage and quit
  -v,   Show version number and quit
```

## Step 2 - Packer Build

Refer to [instructions](./packer/README.md)

## License

Apache 2.0
