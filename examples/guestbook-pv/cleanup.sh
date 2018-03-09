#!/bin/bash

export KUBECONFIG=/home/mjura/kubeconfig

kubectl delete svc frontend
kubectl delete rc frontend

kubectl delete svc redis-slave
kubectl delete rc redis-slave

kubectl delete svc redis-master
kubectl delete rc redis-master
