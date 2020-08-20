#!/usr/bin/bash
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller
helm init --skip-refresh --upgrade --service-account tiller --history-max 10
sleep 10
helm repo add fluxcd https://charts.fluxcd.io
helm repo update

kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

sleep 10
kubectl create namespace flux
helm upgrade -i flux fluxcd/flux \
--set git.url=git@github.com:RachadAbiChahine/minikube-flux-sync.git \
--namespace flux
kubectl wait --for=condition=available --timeout=600s deployment/flux -n flux

kubectl create secret generic flux-git-deploy --from-file=identity=~/.ssh/id_rsa

helm upgrade -i helm-operator fluxcd/helm-operator \
      --set git.ssh.secretName=flux-git-deploy \
      --namespace flux \
      --set helm.versions=v2
kubectl wait --for=condition=available --timeout=600s deployment/helm-operator -n flux

minikube addons enable ingress
minikube addons enable ingress-dns

fluxctl sync --k8s-fwd-ns=flux