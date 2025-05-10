#!/bin/bash

# Script para implantar sua aplicação no Minikube no Windows com WSL

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando o processo de implantação no Windows com WSL...${NC}"

# 1. Parar o Minikube existente (caso exista)
echo -e "${YELLOW}Parando Minikube existente...${NC}"
minikube stop

# 2. Iniciar o Minikube com driver docker (específico para WSL)
echo -e "${YELLOW}Iniciando Minikube com driver Docker no WSL...${NC}"
minikube start --driver=docker --cpus=2 --memory=4096

# 3. Habilitar o Metrics Server para o auto-escalamento
echo -e "${YELLOW}Habilitando o Metrics Server...${NC}"
minikube addons enable metrics-server

# 4. Configurar ambiente para o Docker no Minikube
echo -e "${YELLOW}Configurando ambiente para usar Docker no Minikube...${NC}"
eval $(minikube -p minikube docker-env)

# 5. Informar sobre a imagem Docker que será usada
echo -e "${YELLOW}Usando a imagem Docker: vitorpadovan/gprcvitor:latest${NC}"

# 6. Aplicar os manifestos
echo -e "${YELLOW}Aplicando os manifestos Kubernetes...${NC}"
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

# 7. Aguardar a criação dos pods (importante para evitar o erro SVC_UNREACHABLE)
echo -e "${YELLOW}Aguardando a criação dos pods (30 segundos)...${NC}"
kubectl get pods
echo -e "${YELLOW}Aguardando...${NC}"
sleep 30

# 8. Verificar status
echo -e "${YELLOW}Verificando o status da implantação...${NC}"
kubectl get pods
kubectl get services
kubectl get hpa

# 9. Túnel para acessar a aplicação (executar em outro terminal após este script)
echo -e "${GREEN}Para acessar sua aplicação, execute em outro terminal:${NC}"
echo -e "${GREEN}minikube service minha-aplicacao${NC}"

# 10. Instruções adicionais
echo -e "${GREEN}Implantação concluída!${NC}"
echo -e "${GREEN}Para monitorar o auto-escalamento, execute: kubectl get hpa minha-aplicacao --watch${NC}"
echo -e "${YELLOW}IMPORTANTE: Se os pods não estiverem em execução, execute:${NC}"
echo -e "${YELLOW}kubectl describe pod [nome-do-pod]${NC}"
echo -e "${YELLOW}para verificar o problema.${NC}"