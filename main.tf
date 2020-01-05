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

apt-get update
apt-get upgrade -y

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

//dns entries
resource "cloudflare_record" "rancher_main" {
  count   = var.node_count
  zone_id = var.cf_zone_id
  name    = var.server_host_name
  type    = "A"
  ttl     = var.dns_ttl //must be 1 when proxied
  proxied = false
  value   = scaleway_instance_server.rancherserver[count.index].public_ip
}

#put rancher cluster configuration in yml file
resource "local_file" "rke-config" {
  filename = format("%s/%s", path.root, "rancher_cluster.yml")
  //    internal_address: ${node.private_ip}
  //noinspection HILUnresolvedReference
  content = <<EOF
nodes:
%{for node in scaleway_instance_server.rancherserver~}
  - address: ${node.public_ip}
    user: root
    role: [controlplane, worker, etcd]
%{endfor~}

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h

# Required for external TLS termination with
# ingress-nginx v0.22+
ingress:
  provider: nginx
  options:
    use-forwarded-headers: "true"
EOF
}

data "template_file" "rancher_deploy" {
  template = file("files/rancher-install-le-template.sh")
  vars = {
    hostname       = cloudflare_record.rancher_main[0].hostname
    email          = var.letsencrypt_email
    le_env         = var.letsencrypt_env
    rancher_branch = var.rancher_branch
  }
}
data "template_file" "rancher_install_with_cert" {
  template = file("files/rancher-install-cert-template.sh")
  vars = {
    hostname       = cloudflare_record.rancher_main[0].hostname
    rancher_branch = var.rancher_branch
  }
}
//Decomment for debug
//resource "local_file" "rke_deploy" {
//  filename = format("%s/%s", path.root, "rke-install.sh")
//  content  = data.template_file.rke_deploy.rendered
//}

resource "null_resource" "rke_deploy" {
  provisioner "local-exec" {
    working_dir = path.root
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
#!/usr/bin/env bash
set -x
set -e

rm -f kube_config_rancher_cluster.yml
#rm -f rancher_cluster.yml
rm -f rancher_cluster.rkestate
rke up --config rancher_cluster.yml
EOF
  }
}
#
resource "null_resource" "install_rancher_with_le" {
  count      = var.rancher_le_install
  depends_on = [null_resource.rke_deploy]
  provisioner "local-exec" {
    working_dir = path.root
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
    ${data.template_file.rancher_deploy.rendered}
EOF
  }
}
resource "null_resource" "install_rancher_with_cert" {
  count      = var.rancher_cert_install
  depends_on = [null_resource.rke_deploy]
  provisioner "local-exec" {
    working_dir = path.root
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
    ${data.template_file.rancher_install_with_cert.rendered}
EOF
  }
}