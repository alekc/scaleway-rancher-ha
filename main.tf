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

resource "scaleway_instance_placement_group" "rancherserver" {
  name        = "${var.prefix}-rancher-sg"
  policy_type = "max_availability"
  policy_mode = "optional"
}
#create server
resource "scaleway_instance_server" "rancherserver" {
  count              = var.node_count
  image              = "docker"
  type               = "DEV1-L"
  name               = "rancher-${count.index + 1}"
  cloud_init         = data.template_file.cloud-init.rendered
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
  //  provisioner "remote-exec" {
  //    inline = [
  //      "while [ ! -f /root/signal ]; do sleep 2; done",
  //    ]
  //  }
}
#dns record for it.
data "template_file" "cloud-init" {
  template = file("files/cloud-init.sh")
  vars = {
  }
}
resource "cloudflare_record" "rancher_main" {
  count   = 1
  zone_id = var.cf_zone_id
  name    = var.server_host_name
  type    = "A"
  ttl     = var.dns_ttl //must be 1 when proxied
  proxied = false
  value   = scaleway_instance_server.rancherserver[count.index].public_ip
}

#generate config file.
data "template_file" "rke-config" {
  template = file("files/rancher-cluster-template.yml")
  vars = {
    internal_address = scaleway_instance_server.rancherserver[0].private_ip
    public_address   = scaleway_instance_server.rancherserver[0].public_ip
  }
}
resource "local_file" "rke-config" {
  filename = format("%s/%s", path.root, "rancher_cluster.yml")
  content  = data.template_file.rke-config.rendered
}

#cluster deploy
data "template_file" "rke_deploy" {
  template = file("files/rke-install-template.sh")
}
data "template_file" "rancher_deploy" {
  template = file("files/rancher-install-template.sh")
  vars = {
    hostname = cloudflare_record.rancher_main[0].hostname
    email    = var.letsencrypt_email
    le_env   = var.letsencrypt_env
  }
}
//Decomment for debug
//resource "local_file" "rke_deploy" {
//  filename = format("%s/%s", path.root, "rke-install.sh")
//  content  = data.template_file.rke_deploy.rendered
//}

resource "null_resource" "rke_deploy" {
  triggers = {
    cluster_instance_ids = "${join(",", scaleway_instance_server.rancherserver[*].id)}"
  }
  provisioner "local-exec" {
    working_dir = path.root
    interpreter = ["/bin/bash", "-c"]
    //|| rm -f install.sh
    //bash ${format("%s/%s", path.root, "rke-install.sh")}
    command = <<EOF
    ${data.template_file.rke_deploy.rendered}
EOF
  }
}
resource "null_resource" "install_rancher" {
  depends_on = [null_resource.rke_deploy]
  provisioner "local-exec" {
    working_dir = path.root
    interpreter = ["/bin/bash", "-c"]
    //|| rm -f install.sh
    //bash ${format("%s/%s", path.root, "rke-install.sh")}
    command = <<EOF
    ${data.template_file.rancher_deploy.rendered}
EOF
  }
}