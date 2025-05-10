#!/bin/bash

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=================== SOLUCIONADOR DE PROBLEMAS KUBERNETES COM CARGA LOCAL ====================${NC}"

echo -e "${YELLOW}Passo 1: Garantindo que a imagem está disponível localmente...${NC}"
docker pull vitorpadovan/gprcvitor:latest
if [ $? -ne 0 ]; then
  echo -e "${RED}Erro ao baixar a imagem. Verifique sua conexão com a internet.${NC}"
  echo -e "${RED}Se você já tem a imagem localmente, pode continuar.${NC}"
fi

echo -e "${YELLOW}Passo 2: Parando e removendo tudo do Minikube...${NC}"
kubectl delete all --all
minikube stop
minikube delete

echo -e "${YELLOW}Passo 3: Iniciando Minikube com cache e sem verificação de imagens...${NC}"
minikube start --driver=docker --cpus=2 --memory=4096 --image-mirror-country=cn --insecure-registry="10.0.0.0/24" --cache-images=true

echo -e "${YELLOW}Passo 4: Modificando deployment.yaml para usar apenas imagens locais...${NC}"
sed -i.bak 's|imagePullPolicy: Always|imagePullPolicy: Never|g' deployment.yaml && rm -f deployment.yaml.bak

echo -e "${YELLOW}Passo 5: Qual porta sua aplicação usa? (Pressione Enter para usar 80)${NC}"
read APP_PORT
APP_PORT=${APP_PORT:-80}

echo -e "${YELLOW}Passo 6: Atualizando arquivos de configuração para usar a porta ${APP_PORT}...${NC}"
sed -i.bak "s|containerPort: 80|containerPort: ${APP_PORT}|g" deployment.yaml && rm -f deployment.yaml.bak
sed -i.bak "s|targetPort: 80|targetPort: ${APP_PORT}|g" service.yaml && rm -f service.yaml.bak

echo -e "${YELLOW}Passo 7: Configurando o ambiente Docker para usar o Docker daemon do Minikube...${NC}"
eval $(minikube -p minikube docker-env)

echo -e "${YELLOW}Passo 8: Carregando a imagem diretamente no Docker daemon do Minikube...${NC}"
docker pull vitorpadovan/gprcvitor:latest
if [ $? -ne 0 ]; then
  echo -e "${RED}Não foi possível baixar a imagem novamente. Usando imagem local.${NC}"
  echo -e "${YELLOW}Construindo um tag da imagem com outro nome para testar...${NC}"
  docker tag vitorpadovan/gprcvitor:latest minikube-local/gprcvitor:latest
  # Atualizando o arquivo deployment.yaml para usar a imagem local
  sed -i.bak 's|vitorpadovan/gprcvitor:latest|minikube-local/gprcvitor:latest|g' deployment.yaml && rm -f deployment.yaml.bak
fi

echo -e "${YELLOW}Passo 9: Habilitando o Metrics Server...${NC}"
minikube addons enable metrics-server

echo -e "${YELLOW}Passo 10: Aplicando configurações do Kubernetes...${NC}"
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

echo -e "${YELLOW}Passo 11: Aguardando a criação dos pods (45 segundos)...${NC}"
echo -e "${YELLOW}Status inicial:${NC}"
kubectl get pods
echo -e "${YELLOW}Aguardando...${NC}"
sleep 45

echo -e "${YELLOW}Passo 12: Verificando o status final...${NC}"
kubectl get pods
kubectl get services
kubectl get hpa

# Verifique se os pods estão em execução
POD_STATUS=$(kubectl get pods -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" == "Running" ]; then
  echo -e "${GREEN}=================== SUCESSO! ====================${NC}"
  echo -e "${GREEN}Os pods estão em execução. Você pode acessar a aplicação com:${NC}"
  echo -e "${GREEN}minikube service minha-aplicacao${NC}"
  
  # Abrir automaticamente o serviço
  echo -e "${YELLOW}Abrindo o serviço...${NC}"
  minikube service minha-aplicacao
else
  echo -e "${RED}=================== AINDA HÁ PROBLEMAS ====================${NC}"
  echo -e "${RED}Os pods não estão em execução. Verificando detalhes:${NC}"
  kubectl describe pods
  
  # Se os pods estiverem com ImagePullBackOff, tente uma solução mais drástica
  POD_ERROR=$(kubectl get pods -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
  if [ "$POD_ERROR" == "ImagePullBackOff" ] || [ "$POD_ERROR" == "ErrImagePull" ]; then
    echo -e "${YELLOW}Detectado erro de ImagePullBackOff. Tentando solução alternativa...${NC}"
    
    # Criar um Dockerfile temporário para reconstruir a imagem localmente
    echo -e "${YELLOW}Criando Dockerfile temporário...${NC}"
    echo "FROM vitorpadovan/gprcvitor:latest" > Dockerfile.temp
    
    # Construir imagem localmente com o docker daemon do Minikube
    echo -e "${YELLOW}Construindo imagem localmente...${NC}"
    docker build -t minikube-app:latest -f Dockerfile.temp .
    
    # Atualizar o deployment para usar a imagem local
    echo -e "${YELLOW}Atualizando deployment para usar imagem local...${NC}"
    kubectl set image deployment/minha-aplicacao minha-aplicacao=minikube-app:latest
    
    # Forçar a política de pull para Never
    echo -e "${YELLOW}Forçando política de pull para Never...${NC}"
    kubectl patch deployment minha-aplicacao -p '{"spec":{"template":{"spec":{"containers":[{"name":"minha-aplicacao","imagePullPolicy":"Never"}]}}}}'
    
    echo -e "${YELLOW}Aguardando mais 30 segundos...${NC}"
    sleep 30
    
    echo -e "${YELLOW}Status final após tentativa alternativa:${NC}"
    kubectl get pods
  fi
  
  echo -e "${YELLOW}Dicas adicionais:${NC}"
  echo -e "1. Verifique os logs: ${GREEN}kubectl logs [nome-do-pod]${NC}"
  echo -e "2. Verifique se sua imagem funciona localmente: ${GREEN}docker run -p ${APP_PORT}:${APP_PORT} vitorpadovan/gprcvitor:latest${NC}"
  echo -e "3. Considere configurar um proxy: ${GREEN}minikube start --docker-env HTTP_PROXY=http://your-proxy:port${NC}"
fi