REM # 1. Excluir todos os recursos do Kubernetes (pods, services, deployments, etc)
kubectl delete all --all

REM # 2. Parar o Minikube
minikube stop

REM #3. Se quiser realmente "zerar" tudo, você pode excluir o cluster Minikube
minikube delete

docker system prune -a --volumes --force