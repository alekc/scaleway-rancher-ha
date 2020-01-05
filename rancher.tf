###################INSTALLATION WITH lets encrypt certificate#####################################
# currently not working on stable due to issues with letsencrypt.
data "template_file" "rancher_deploy" {
  template = file("files/rancher-install-le-template.sh")
  vars = {
    hostname       = var.rancher_hostname
    email          = var.letsencrypt_email
    le_env         = var.letsencrypt_env
    rancher_branch = var.rancher_branch
  }
}

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
###################INSTALLATION WITH CERTIFICATE#####################################
data "template_file" "rancher_install_with_cert" {
  template = file("files/rancher-install-cert-template.sh")
  vars = {
    hostname       = var.rancher_hostname
    rancher_branch = var.rancher_branch
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