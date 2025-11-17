variable "arch_iso_url" {
  description = "URL for the Arch Linux ISO"
  type        = string
  default     = "https://archlinux.org/iso/latest/archlinux-x86_64.iso"
}

variable "arch_iso_checksum" {
  description = "Checksum for the Arch Linux ISO"
  type        = string
  default     = "SHA256:your_checksum_here"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "ArchLinuxVM"
}

variable "vm_memory" {
  description = "Memory size for the virtual machine in MB"
  type        = number
  default     = 2048
}

variable "vm_cpus" {
  description = "Number of CPUs for the virtual machine"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Disk size for the virtual machine in MB"
  type        = number
  default     = 20480
}