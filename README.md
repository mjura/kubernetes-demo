# OpenStack Magnum & Kubernetes demo

This repo contains Kubernetes demo with modified `guestbook` example for Kubernetes cluster setup without `skydns` addon installed. It relays on environment variables, that's way it is important to deploy all components in proper order according to this documentation.

# Installatation 

## Deploy OpenStack with Magnum

This demo requires full OpenStack installation with Magnum component, it can be done for example with SUSE OpenStack Cloud 7. For proper demo it is required to prepare at least 3 Nova Computes with kvm as hypervisor.

## Prepare OpenStack environment

Download and upload Magnum SLES based image.

Link to the image
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

## Prepare OpenStack Magnum and deploy Kubernetes cluster

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
                       --tls-disabled \
                       --registry-enabled \
                       --label registry_url=https://docker-testing-registry.suse.de
```

Create a bay with one `kube-master` node and one `kube-minion` node
```
magnum bay-create --name susek8sbay --baymodel susek8sbaymodel --node-count 1
```

Demonstrate auto-scale for kube-minions and add one more `kube-minion` node
```
magnum bay-update susek8sbay replace node_count=2
```

## Deploy `guestbook` application on Kubernetes cluster

Clone `guestbook` example from this repository on node with docker installed and credentials for Kubernetes cluster deplyed by Magnum
```
git clone https://github.com/mjura/kubernetes-demo
```

And go to the example 
```
cd ~/kubernetes-demo/examples/guestbook
```

Check if Kubernetes cluster is healthy and you have right endpoints crendtials
```
kubectl cluster-info
```

Deploy `redis-master` replication controller and service
```
kubectl create -f redis-master-controller.yaml
kubectl create -f redis-master-service.yaml
```

Check status for replication controllers, pods and service
```
kubectl get rc,pods,service
```

Deploy `redis-slave` replication controller and service
```
kubectl create -f redis-slave-controller.yaml
kubectl create -f redis-slave-service.yaml
```

Check status for replication controllers, pods and service
```
kubectl get rc,pods,service

```

When `redis-slave` pods will be ready, auto-scale it and add one more replica
```
kubectl scale --replicas=2 rc/redis-slave
```

Check logs from `redis-slave` to be sure that they are replicating database from `redis-master`
```
kubectl logs <redis-slave-PODID>
```

Deploy `frontend` web application
```
kubectl create -f frontend-controller.yaml
kubectl create -f frontend-service.yaml
```

You should get service port (tcp:3XXXX) as output to configure Neutron LoadBalancer. Create Neutron LoadBalancer new pool named `guestbook`, add VIP and Floating IP, as members of this pool pick up `kube-mionions`

Access application using Floating IP

## Modify `guestbook` application and demonstrate rolling-updates

Go to container application template
```
cd ~/kubernetes/examples/guestbook/php-redis/
```
Edit `index.html` file and uncomment line with image src
```
<!-- <img src="suse-logo.png" alt="SUSE Logo"> -->
```
to
```
<img src="suse-logo.png" alt="SUSE Logo">
```

Build new docker image and push it to docker-registry service
```
docker build -t docker-testing-registry.suse.de/mjura/guestbook:v2 .
docker push docker-testing-registry.suse.de/mjura/guestbook:v2
```

Deploy new version of application using rolling update feature from Kubernetes
```
kubectl rolling-update frontend --image=docker-testing-registry.suse.de/mjura/guestbook:v2
```

After this will be done refresh webrowser with link to application

