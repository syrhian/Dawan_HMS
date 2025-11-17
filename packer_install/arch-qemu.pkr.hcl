packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
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

source "qemu" "arch" {
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  output_directory = "output/archlinux"
  accelerator      = "tcg"
  disk_size        = "300G"
  memory           = 4096
  cpus             = 4
  headless         = false

  ssh_username = "dawan"
  ssh_password = "Passw0rd"
  ssh_timeout  = "30m"

  http_directory = "./setup"

  boot_wait    = "180s"
  boot_command = [
    "<enter><wait20>",
    "curl -fsSL http://{{ .HTTPIP }}:{{ .HTTPPort }}/user_credentials.json -o /tmp/user_credentials.json || curl -v http://{{ .HTTPIP }}:{{ .HTTPPort }}/user_credentials.json -o /tmp/user_credentials.json<enter>",
    "archinstall --config-url https://raw.githubusercontent.com/syrhian/Dawan_HMS/refs/heads/master/setup/user_configuration.json --creds /tmp/user_credentials.json --silent<enter>"
  ]
}

build {
  name    = "archlinux"
  sources = ["source.qemu.arch"]

}
