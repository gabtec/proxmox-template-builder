variable "node_ip" { type = string }

variable "node_name" {
  type    = string
  default = "pve"
}

variable "node_user" {
  type    = string
  default = "root@pam"
}

variable "node_passw" {
  type      = string
  sensitive = true
}

variable "src_tpl_vm_id" { type = number }

variable "final_vm_id" { type = number }

variable "ubuntu_version" {
  type    = string
  default = "24.04"
}

variable "ubuntu_codenames" {
  type = map(string)
  default = {
    "22.04" = "jammy"
    "24.04" = "noble"
  }
}
