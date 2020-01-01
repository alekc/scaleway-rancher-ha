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

#create server
resource "scaleway_instance_server" "rancherserver" {
  count             = 1
  image             = "docker"
  type              = "DEV1-L"
  name              = "rancher-${count.index + 1}"
  cloud_init        = data.template_file.cloud-init.rendered
  enable_dynamic_ip = true
  provisioner "remote-exec" {
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "root"
      private_key = "${file("~/.ssh/id_rsa")}"
      timeout     = "2m"
    }

    inline = [
      "echo Waiting for cloud-init...",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
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
data "template_file" "cluster_deploy" {
  template = file("files/install.sh")
  vars = {
    hostname = cloudflare_record.rancher_main[0].hostname
    email    = var.letsencrypt_email
    le_env   = var.letsencrypt_env
  }
}

resource "null_resource" "install_rancher" {
  depends_on = [local_file.rke-config]
  provisioner "local-exec" {
    command = <<EOF
    ${data.template_file.cluster_deploy.rendered}
EOF
  }
}