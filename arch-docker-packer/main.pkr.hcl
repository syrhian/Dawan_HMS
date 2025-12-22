source "docker" "arch" {
  image  = var.base_image
  commit = true
  changes = [
    "CMD [\"/bin/zsh\"]"
  ]
}

build {
  sources = ["source.docker.arch"]

  provisioner "file" {
    source      = "scripts/"
    destination = "/tmp/scripts/"
  }

  provisioner "shell" {
    environment_vars = [
      "USERNAME=${var.username}",
      "UID=${var.uid}",
      "GID=${var.gid}"
    ]
    inline = [
      "chmod +x /tmp/scripts/*.sh",
      "/tmp/scripts/setup.sh"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = var.image_name
      tags       = [var.image_tag]
    }
  }
}
