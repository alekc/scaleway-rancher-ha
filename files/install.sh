#!/usr/bin/env bash
set +x
set +e
#
rke up --config rancher_cluster.yml

#check nodes
export KUBECONFIG=$(pwd)/kube_config_rancher_cluster.yml
kubectl  get nodes
kubectl get pods --all-namespaces

#add helm repo
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system

# cert-manager
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.12.0

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=${hostname} \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=${email} \
  --set letsEncrypt.environment=${le_env}

kubectl -n cattle-system rollout status deploy/rancher
