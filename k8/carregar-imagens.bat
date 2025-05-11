@echo off 
echo Carregando imagens para minikube... 
 
docker load -i .\imagens\kicbase.tar 
docker load -i .\imagens\kube-apiserver.tar 
docker load -i .\imagens\kube-controller-manager.tar 
docker load -i .\imagens\kube-scheduler.tar 
docker load -i .\imagens\kube-proxy.tar 
docker load -i .\imagens\pause.tar 
docker load -i .\imagens\etcd.tar 
docker load -i .\imagens\coredns.tar 
docker load -i .\imagens\metrics-server.tar 
docker load -i .\imagens\dashboard.tar 
docker load -i .\imagens\metrics-scraper.tar 
 
echo Carregando imagens no minikube... 
 
