# OpenStack Magnum & Kubernetes demo

This repo contains Kubernetes demo with modified `guestbook` example for Kubernetes cluster setup without `skydns` addon installed. It relays on environment variables, that's way it is important to deploy all components in proper order according to this documentation.

# Installatation 

## Deploy OpenStack with Magnum

This demo requires full OpenStack installation with Magnum component, it can be done for example with SUSE OpenStack Cloud 7. For proper demo it is required to prepare at least 3 Nova Computes with kvm as hypervisor.

## Prepare OpenStack environment

Download and upload Magnum SLES based image. Link to the image
http://download.suse.de/ibs/Devel:/Docker:/Images:/SLE12SP1-JeOS-k8s-magnum/images/SLE12SP1-JeOS-k8s-magnum.x86_64.qcow2

Source credentials
```
source .openrc
```

Upload image to Glance service
```
glance image-create --name SLE12SP1-JeOS-k8s-magnum \
                    --visibility public \
                    --disk-format qcow2 \
                    --os-distro opensuse \
                    --container-format bare \
                    --file ./SLE12SP1-JeOS-k8s-magnum.x86_64.qcow2
```
Import SSH key from controller node to use with the baymodel
```
nova keypair-add --pub-key ~/.ssh/id_rsa.pub controller-ssh
```
Create Magnum flavor
```
nova flavor-create --is-public true m1.magnum 9 1024 10 1
```

## Create baymodel in OpenStack Magnum and deploy Kubernetes cluster

Create baymodel
```
magnum baymodel-create --name susek8sbaymodel \
                       --image-id SLE12SP1-JeOS-k8s-magnum \
                       --keypair-id controller-ssh \
                       --external-network-id floating \
                       --dns-nameserver 10.160.0.1 \
                       --flavor-id m1.magnum \
                       --master-flavor-id m1.magnum \
                       --docker-volume-size 5 \
                       --network-driver flannel \
                       --coe kubernetes \
                       --tls-disabled
```
Create a bay with one `kube-master` node and one `kube-minion` node
```
magnum bay-create --name susek8sbay --baymodel susek8sbaymodel --node-count 1
```
Demonstrate auto-scale for kube-minions and add one more `kube-minion` node
```
magnum bay-update susek8sbay replace node_count=2
```

```
