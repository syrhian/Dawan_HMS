variable "base_image" {
  type    = string
  default = "archlinux:latest"
  description = "Base Docker image to start from"
}

variable "image_name" {
  type    = string
  default = "hms/arch-devops"
  description = "Resulting Docker repository/name"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "username" {
  type    = string
  default = "dawan"
}

variable "uid" {
  type    = number
  default = 1000
}

variable "gid" {
  type    = number
  default = 1000
}

variable "extra_packages" {
  type    = list(string)
  default = [
    "sudo", "git", "curl", "neovim", "zsh", "tmux",
    "python", "python-pip", "jq", "yq"
  ]
}
