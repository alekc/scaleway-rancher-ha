resource "scaleway_instance_security_group" "control-plane" {
  description             = "Security group for rancher control/etcd plane"
  name                    = "${var.prefix}-rancher-ecdp-control"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  dynamic "inbound_rule" {
    for_each = ["80", "443", "22", "6443", "2379", "2380", "10250"]
    content {
      action   = "accept"
      port     = inbound_rule.value
      protocol = "TCP"
    }
  }
  inbound_rule {
    action   = "accept"
    port     = "8472"
    protocol = "UDP"
  }
}
