# 1. Excluir todos os recursos do Kubernetes (pods, services, deployments, etc)
kubectl delete all --all

# 2. Parar o Minikube
minikube stop

# 3. Se quiser realmente "zerar" tudo, você pode excluir o cluster Minikube
minikube delete