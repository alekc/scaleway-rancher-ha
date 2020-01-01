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
variable "server_host_name" {}
variable "dns_ttl" {
  default = 120
}