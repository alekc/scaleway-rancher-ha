output "rancher_ips" {
  value = scaleway_instance_server.rancherserver[*].public_ip
}
output "rancher_cluster_token" {
  value = rancher2_bootstrap.admin.token
}