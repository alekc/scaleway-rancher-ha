// this file works with older versions of kubernetes (up to 15),
// while I am waiting for support of rke 1.x, I am moving to local provisioner, but feel free to get inspired by this

//
//resource rke_cluster "cluster" {
//  #attempt to work around the race condition
//  depends_on = [cloudflare_record.rancher_main]
//  nodes {
//    address          = scaleway_instance_server.rancherserver[0].public_ip
//    internal_address = scaleway_instance_server.rancherserver[0].private_ip
//    user             = "root"
//    role             = ["controlplane", "worker", "etcd"]
//    ssh_key_path     = "~/.ssh/id_rsa"
//  }
//  kubernetes_version = "v1.16.3-rancher1-1"
//  services {
//    etcd {
//      # if external etcd used
//      #path      = "/etcdcluster"
//      #ca_cert   = file("ca_cert")
//      #cert      = file("cert")
//      #key       = file("key")
//
//      # for etcd snapshots
//      #backup_config {
//      #  interval_hours = 12
//      #  retention = 6
//      #  # s3 specific parameters
//      #  #s3_backup_config {
//      #  #  access_key = "access-key"
//      #  #  secret_key = "secret_key"
//      #  #  bucket_name = "bucket-name"
//      #  #  region = "region"
//      #  #  endpoint = "s3.amazonaws.com"
//      #  #}
//      #}
//    }
//  }
//  addons_include = [
//    //    "https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml",
//    "https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml"
//  ]
//}
//#dump config
//resource "local_file" "kube_cluster_yaml" {
//  filename = format("%s/%s", path.root, "kube_config_cluster.yml")
//  content  = rke_cluster.cluster.kube_config_yaml
//}
//
//provider "kubernetes" {
//  config_path = local_file.kube_cluster_yaml.filename
//}
//resource "kubernetes_namespace" "cert-manager-ns" {
//  metadata {
//    annotations = {
//    }
//
//    labels = {
//      "certmanager.k8s.io/disable-validation" = "true"
//    }
//    name = "cert-manager"
//  }
//}
//resource "kubernetes_namespace" "cattle-system" {
//  metadata {
//    name = "cattle-system"
//  }
//}