#put rancher cluster configuration in yml file
resource "local_file" "rke-config" {
  filename = format("%s/%s", path.root, "rancher_cluster.yml")
  //noinspection HILUnresolvedReference
  content = <<EOF
nodes:
%{for node in scaleway_instance_server.rancherserver~}
  - address: ${node.public_ip}
    internal_address: ${node.private_ip}
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
resource "null_resource" "rke_deploy" {
  depends_on = [local_file.rke-config]
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