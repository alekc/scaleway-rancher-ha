provider "scaleway" {
  access_key      = var.scw_access_key
  secret_key      = var.scw_secret_key
  organization_id = var.scw_organization_id
  zone            = var.scw_zone
  region          = "fr-par"
  version         = "~> 1.13"
}
provider "cloudflare" {
  version   = "~> 2.0"
  api_token = var.cf_api_token
  email     = var.cf_email
}
data "scaleway_instance_image" "docker" {
  architecture = "x86_64"
  name         = "docker"
}

//placegroup
resource "scaleway_instance_placement_group" "rancherserver" {
  name        = "${var.prefix}-rancher-sg"
  policy_type = "max_availability"
  policy_mode = "optional"
}

#control server
resource "scaleway_instance_server" "rancherserver" {
  count              = var.node_count
  image              = "docker"
  type               = "DEV1-L"
  name               = "${var.prefix}-rancher-${count.index + 1}"
  security_group_id  = scaleway_instance_security_group.control-plane.id
  cloud_init         = <<EOF
#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

#apt-get update
#apt-get upgrade -y

#workaround to avoid "Failed to get job complete status for job rke-network-plugin-deploy-job in namespace kube-system"
docker pull rancher/pause:3.1
EOF
  placement_group_id = scaleway_instance_placement_group.rancherserver.id
  enable_dynamic_ip  = true
  provisioner "remote-exec" {
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      timeout     = "2m"
    }

    inline = [
      "echo Waiting for cloud-init...",
      "cloud-init status --wait",
      "echo cloud-init is finished!",
    ]
  }
}
output "rancher_ips" {
  value = scaleway_instance_server.rancherserver[*].public_ip
}