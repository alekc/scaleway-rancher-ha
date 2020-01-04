#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

#apt-get update
#apt-get upgrade -y

#workaround to avoid "Failed to get job complete status for job rke-network-plugin-deploy-job in namespace kube-system"
docker pull rancher/pause:3.1