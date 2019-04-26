#!/bin/bash
#
# Author: Pierre Pfister <ppfister@cisco.com>
#
# Largely inspired from contiv-VPP vagrant file.
#

set -ex
echo Args passed: [[ $@ ]]


k8s_service_cidr=$K8S_SERVICE_CIDR
base_ip6=$K8S_IP6_PREFIX

vm_conf=""
vm_name=""
vm_id=""
vm_hostname=""
function get_vm_conf {
	vm_name="$1"
	vm_conf=$(echo "$VMS_CONF" | awk "BEGIN{ RS=\",\"; FS=\":\"; ORS=\" \" } \$1==\"$vm_name\" { print \$1, \$2, \$3 }")
	vm_id=$(echo "$vm_conf" | awk '{ print $3 }')
	vm_hostname=$(echo "$vm_conf" | awk '{ print $2 }')
}

self_name="$1"
get_vm_conf "$self_name"
self_id="$vm_id"
self_hostname="$vm_hostname"


echo "Configuring Cluster DNS"
k8s_dns=${k8s_service_cidr}:a
sudo sed -i "s/--cluster-dns=.* /--cluster-dns=$k8s_dns /" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "Configuring CNI bridge"
sudo rm /etc/cni/net.d/* || true
sudo mkdir -p /etc/cni/net.d/

if [ ! -f "/vagrant/config/kubadm-join-${self_name}-done" ]; then
  echo "Initiate kubeadm join sequence !"
  cmd=$(grep "^  kubeadm join" /vagrant/config/cert)
  sudo $cmd
  touch "/vagrant/config/kubadm-join-${self_name}-done"
fi
