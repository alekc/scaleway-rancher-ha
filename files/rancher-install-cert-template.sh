#!/usr/bin/env bash
set -x
set -e

#check nodes
export KUBECONFIG=$(pwd)/kube_config_rancher_cluster.yml
kubectl get nodes
kubectl get pods --all-namespaces

#add helm repo
helm repo add rancher-${rancher_branch} https://releases.rancher.com/server-charts/${rancher_branch}
kubectl create namespace cattle-system

kubectl -n cattle-system create secret tls tls-rancher-ingress \
  --cert=tls.crt \
  --key=tls.key

helm install rancher rancher-${rancher_branch}/rancher \
  --namespace cattle-system \
  --set hostname=${hostname} \
  --set ingress.tls.source=secret

kubectl -n cattle-system rollout status deploy/rancher
