#!/bin/bash

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}============== IMPLANTAÇÃO NO KUBERNETES (MODO OFFLINE) ==============${NC}"

# 1. Parar o Minikube existente (caso exista)
echo -e "${YELLOW}Parando Minikube existente...${NC}"
minikube stop

# 2. Iniciar o Minikube com configurações para funcionar offline
echo -e "${YELLOW}Iniciando Minikube com configurações para modo offline...${NC}"
minikube start --driver=docker --cpus=2 --memory=4096 \
  --image-mirror-country=cn \
  --insecure-registry="10.0.0.0/24" \
  --cache-images=true

# 3. Habilitar o Metrics Server para o auto-escalamento
echo -e "${YELLOW}Habilitando o Metrics Server...${NC}"
minikube addons enable metrics-server

# 4. Configurar ambiente para o Docker no Minikube
echo -e "${YELLOW}Configurando ambiente para usar Docker no Minikube...${NC}"
eval $(minikube -p minikube docker-env)

# 5. Informar sobre a imagem Docker que será usada
echo -e "${YELLOW}Usando a imagem Docker: vitorpadovan/gprcvitor:latest${NC}"

# 6. Verificar se a imagem está disponível localmente
echo -e "${YELLOW}Verificando disponibilidade da imagem localmente...${NC}"
if ! docker images | grep -q "vitorpadovan/gprcvitor"; then
  echo -e "${YELLOW}Imagem não encontrada localmente. Tentando baixar...${NC}"
  docker pull vitorpadovan/gprcvitor:latest
  if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao baixar a imagem. Por favor, certifique-se de que você tem a imagem disponível localmente.${NC}"
    exit 1
  fi
fi

# 7. Criar tag da imagem para uso com o Minikube
echo -e "${YELLOW}Criando tag da imagem para uso com o Minikube...${NC}"
docker tag vitorpadovan/gprcvitor:latest minikube/gprcvitor:latest

# 8. Aplicar os manifestos
echo -e "${YELLOW}Aplicando os manifestos Kubernetes...${NC}"
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

# 9. Aguardar a criação dos pods
echo -e "${YELLOW}Aguardando a criação dos pods (30 segundos)...${NC}"
kubectl get pods
echo -e "${YELLOW}Aguardando...${NC}"
sleep 30

# 10. Verificar status
echo -e "${YELLOW}Verificando o status da implantação...${NC}"
kubectl get pods
kubectl get services
kubectl get hpa

# 11. Se os pods não estiverem em execução, tentar correção
POD_STATUS=$(kubectl get pods -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
  echo -e "${RED}Os pods não estão em execução. Tentando corrigir...${NC}"
  
  # Verificar o problema
  POD_NAME=$(kubectl get pods -o jsonpath='{.items[0].metadata.name}')
  kubectl describe pod $POD_NAME
  
  # Se for problema de imagem, tentar abordagem alternativa
  if kubectl describe pod $POD_NAME | grep -q "ErrImagePull\|ImagePullBackOff"; then
    echo -e "${YELLOW}Problema com a imagem detectado. Tentando abordagem alternativa...${NC}"
    
    # Criar um Dockerfile temporário
    echo -e "${YELLOW}Criando Dockerfile temporário...${NC}"
    echo "FROM vitorpadovan/gprcvitor:latest" > Dockerfile.temp
    
    # Construir imagem localmente
    echo -e "${YELLOW}Construindo imagem localmente...${NC}"
    docker build -t offline-app:latest -f Dockerfile.temp .
    
    # Atualizar o deployment para usar a nova imagem
    echo -e "${YELLOW}Atualizando deployment para usar imagem local...${NC}"
    kubectl set image deployment/minha-aplicacao minha-aplicacao=offline-app:latest
    
    # Forçar política de pull para Never
    echo -e "${YELLOW}Forçando política de pull para Never...${NC}"
    kubectl patch deployment minha-aplicacao -p '{"spec":{"template":{"spec":{"containers":[{"name":"minha-aplicacao","imagePullPolicy":"Never"}]}}}}'
    
    echo -e "${YELLOW}Aguardando mais 30 segundos...${NC}"
    sleep 30
    
    echo -e "${YELLOW}Verificando status após correção...${NC}"
    kubectl get pods
  fi
fi

# 12. Túnel para acessar a aplicação
echo -e "${GREEN}Para acessar sua aplicação, execute em outro terminal:${NC}"
echo -e "${GREEN}minikube service minha-aplicacao${NC}"

# 13. Instruções adicionais
echo -e "${GREEN}Implantação concluída!${NC}"
echo -e "${GREEN}Para monitorar o auto-escalamento, execute: kubectl get hpa minha-aplicacao --watch${NC}"
echo -e "${YELLOW}Para testar o auto-escalamento, você pode gerar carga com:${NC}"
echo -e "${YELLOW}kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c \"while sleep 0.01; do wget -q -O- http://minha-aplicacao; done\"${NC}"