variable "scw_access_key" {}
variable "scw_secret_key" {}
variable "scw_organization_id" {}
variable "scw_zone" {
  default = "fr-par-1"
}

variable "cf_api_token" {}
variable "cf_email" {}
variable "cf_zone_id" {
  type = string
}
variable "letsencrypt_email" {}
variable "letsencrypt_env" {
  default = "staging"
}

variable "prefix" {
  default = ""
}
variable "instance_name" {
  default = "rancher"
}

variable "dns_ttl" {
  default = 120
}
variable "node_count" {
  default = "1"
}
variable "rancher_branch" {
  default = "stable"
}
variable "rancher_le_install" {
  description = "Set to 1 for lets encrypt certificate installation"
  default     = "0"
}
variable "rancher_cert_install" {
  description = "Set to 1 for lets encrypt certificate installation"
  default     = "0"
}
variable "rancher_hostname" {
  description = "Rancher hostname"
  default     = "rancher"
}
variable "rancher_password" {
  default = "nimda123!"
}