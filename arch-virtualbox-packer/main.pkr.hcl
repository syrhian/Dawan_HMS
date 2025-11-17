build "virtualbox-iso" {
  iso_url            = "http://archlinux.org/iso/latest/archlinux-x86_64.iso"
  iso_checksum       = "SHA256:your_iso_checksum_here"
  output_directory   = "output-arch"
  vm_name            = "ArchLinux"
  disk_size          = 20480
  boot_command       = [
    "<wait>",
    "ip=dhcp<wait>",
    "arch<wait>",
    "<enter>"
  ]
  boot_wait          = "10s"
  http_directory     = "http"
  ssh_username       = "root"
  ssh_password       = "root"
  ssh_timeout        = "10m"
  shutdown_command    = "shutdown now"
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/arch_install.sh",
    "/tmp/arch_install.sh"
  ]
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/setup.sh",
    "/tmp/setup.sh"
  ]
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/install_vbox_guest_additions.sh",
    "/tmp/install_vbox_guest_additions.sh"
  ]
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/cleanup.sh",
    "/tmp/cleanup.sh"
  ]
}

provisioner "shell" {
  inline = [
    "chmod +x /tmp/shutdown.sh",
    "/tmp/shutdown.sh"
  ]
}