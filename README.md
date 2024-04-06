# proxmox-template-builder
:rocket: Proxmox template builder tools

This is a very opinionated version, that aims to bring simplification.
The script will download an oficial Ubuntu cloud image and create a Proxmox Template VM with it.

Also it is intended to use this vm template with terraform/openTofu to deploy new VM's,
and then we can modify settings like cpu or memory.

To keep this simple:
- the only supported distro is **Ubuntu Server**
- the template will have 2 cpus and 1024MiB of memory
- the network interface will be attached to **vmbr0**

:building_construction: WIP (in future versions will have a cli parameter):
- for now storage pool is **local-lvm** (to change it you must edit the script)
- for now the ubuntu version used is **22.04** (to change it you must edit the script)

What you can choose:
- the distro version (e.g. 20.04, 22.04, etc)
- the template VM ID (defaults to 9000)

## Usage
SSH into your proxmox server, and run:

```sh
usage: ./build.sh [options...] <vm_id>
 -d, --distro-version Distro version/code, e.g. 22.04
 -s, --storage-pool   Destiny Storage Pool Name
 -h, --help           Show help/usage and quit 
 -v, --version        Show version number and quit 
```

## License
Apache 2.0