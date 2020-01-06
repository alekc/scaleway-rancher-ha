resource "scaleway_lb_beta" "rancher-control" {
  region = "fr-par"
  type   = "lb-s"
  name   = "${var.prefix}-rancher-control"
}
resource "scaleway_lb_frontend_beta" "rancher_https" {
  lb_id        = scaleway_lb_beta.rancher-control.id
  backend_id   = scaleway_lb_backend_beta.rancher_https.id
  name         = "rancher-control-https"
  inbound_port = "443"
}
resource "scaleway_lb_backend_beta" "rancher_https" {
  lb_id                    = scaleway_lb_beta.rancher-control.id
  name                     = "rancher-control-https"
  forward_protocol         = "tcp"
  forward_port             = "443"
  health_check_delay       = "5s"
  health_check_timeout     = "5s"
  health_check_max_retries = "6"
  sticky_sessions          = "table"
  server_ips               = scaleway_instance_server.rancherserver[*].public_ip
}
#general dns entry.
resource "cloudflare_record" "cluster_lb" {
  zone_id = var.cf_zone_id
  name    = var.rancher_hostname
  type    = "A"
  ttl     = var.dns_ttl //must be 1 when proxied
  proxied = false
  value   = scaleway_lb_beta.rancher-control.ip_address
  //  value = scaleway_instance_server.rancherserver[0].public_ip
}
