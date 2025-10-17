// packer configuration for building Arch Linux VM image for VMware
packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "iso_url" {
  default = "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
}
variable "iso_checksum" {
  default = "none"
}

source "vmware-iso" "arch" {
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum

  vm_name          = "archlinux_vmware"
  output_directory = "output/archlinux_vmware"

  // 300 GiB en MiB
  disk_size        = 307200
  memory           = 4096
  cpus             = 4
  headless         = false

#  communicator = "ssh"
#  ssh_username = "dawan"
#  ssh_password = "Passw0rd"
#  ssh_timeout  = "30m"


  http_directory = "./setup"

  boot_wait    = "40s"
  boot_command = [
    "<enter><wait20>",
    "curl -fsSL http://{{ .HTTPIP }}:{{ .HTTPPort }}/user_credentials.json -o /tmp/user_credentials.json || curl -v http://{{ .HTTPIP }}:{{ .HTTPPort }}/user_credentials.json -o /tmp/user_credentials.json<enter>",
    "archinstall --config-url https://raw.githubusercontent.com/syrhian/Dawan_HMS/refs/heads/packer/setup/user_configuration.json --creds /tmp/user_credentials.json --silent<enter>"
  ]

  // Facultatif: arrêt propre quand Packer termine
  shutdown_command = "echo 'Passw0rd' | sudo -S poweroff"
}

build {
  name    = "archlinux_vmware"
  sources = ["source.vmware-iso.arch"]
}
