#!/usr/bin/env bash
set -x
set -e

rm -f kube_config_rancher_cluster.yml
#rm -f rancher_cluster.yml
rm -f rancher_cluster.rkestate

#
rke up --config rancher_cluster.yml
