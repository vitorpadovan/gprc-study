#!/bin/bash

# Script para implantar sua aplicação no Minikube

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando o processo de implantação...${NC}"

# 1. Verificar se o Minikube está em execução
echo -e "${YELLOW}Verificando o status do Minikube...${NC}"
minikube status
if [ $? -ne 0 ]; then
  echo -e "${RED}Minikube não está em execução. Iniciando...${NC}"
  minikube start --cpus=2 --memory=4096
else
  echo -e "${GREEN}Minikube já está em execução.${NC}"
fi

# 2. Habilitar o Metrics Server para o auto-escalamento
echo -e "${YELLOW}Habilitando o Metrics Server...${NC}"
minikube addons enable metrics-server

# 3. Se for usar imagem local, carregá-la no Minikube
echo -e "${YELLOW}Qual o nome da sua imagem Docker? (ex: minha-imagem:latest)${NC}"
read IMAGE_NAME

echo -e "${YELLOW}Carregando a imagem Docker $IMAGE_NAME para o Minikube...${NC}"
minikube image load $IMAGE_NAME

# 4. Substituir o nome da imagem nos arquivos YAML
echo -e "${YELLOW}Atualizando o nome da imagem no arquivo deployment.yaml...${NC}"
sed -i "s|sua-imagem-docker:latest|$IMAGE_NAME|g" deployment.yaml

# 5. Aplicar os manifestos
echo -e "${YELLOW}Aplicando os manifestos Kubernetes...${NC}"
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

# 6. Verificar status
echo -e "${YELLOW}Verificando o status da implantação...${NC}"
kubectl get pods
kubectl get services
kubectl get hpa

# 7. Obter URL para acesso externo
echo -e "${YELLOW}Obtendo URL para acesso à aplicação...${NC}"
minikube service minha-aplicacao --url

echo -e "${GREEN}Implantação concluída!${NC}"
echo -e "${GREEN}Você pode acessar sua aplicação pelo URL acima.${NC}"
echo -e "${GREEN}Para monitorar o auto-escalamento, execute: kubectl get hpa minha-aplicacao --watch${NC}"