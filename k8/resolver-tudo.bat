@echo off
echo Iniciando solucao de problemas do Kubernetes...

REM Passo 1: Parando e removendo tudo do Minikube
echo Passo 1: Parando e removendo tudo do Minikube...
kubectl delete all --all
minikube stop
minikube delete

REM Passo 2: Iniciando Minikube com configurações otimizadas
echo Passo 2: Iniciando Minikube com configuracoes otimizadas...
minikube start --driver=docker --cpus=2 --memory=4096 --alsologtostderr

REM Passo 3: Habilitando o Metrics Server
echo Passo 3: Habilitando o Metrics Server...
minikube addons enable metrics-server

REM Passo 4: Verificando a imagem Docker
echo Passo 4: Verificando a imagem Docker...
docker pull vitorpadovan/gprcvitor:latest

REM Passo 5: Perguntando sobre a porta
set /p APP_PORT=Qual porta sua aplicacao usa? (Pressione Enter para usar 80): 
if "%APP_PORT%"=="" set APP_PORT=80

REM Passo 6: Atualizando arquivos de configuração para usar a porta correta
echo Passo 6: Atualizando arquivos de configuracao para usar a porta %APP_PORT%...
powershell -Command "(Get-Content deployment.yaml) -replace 'containerPort: 80', 'containerPort: %APP_PORT%' | Set-Content deployment.yaml"
powershell -Command "(Get-Content service.yaml) -replace 'targetPort: 80', 'targetPort: %APP_PORT%' | Set-Content service.yaml"

REM Passo 7: Tentando carregar a imagem para o Minikube
echo Passo 7: Carregando a imagem para o Minikube...
minikube image load vitorpadovan/gprcvitor:latest

REM Passo 8: Aplicando configurações do Kubernetes
echo Passo 8: Aplicando configuracoes do Kubernetes...
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

REM Passo 9: Aguardando a criação dos pods
echo Passo 9: Aguardando a criacao dos pods (45 segundos)...
echo Status inicial:
kubectl get pods
echo Aguardando...
timeout /t 45 /nobreak

REM Passo 10: Verificando o status final
echo Passo 10: Verificando o status final...
kubectl get pods
kubectl get services
kubectl get hpa

REM Verificar se os pods estão em execução (simplificado para BAT)
echo.
echo Verificando o status dos pods...
kubectl get pods

echo.
echo Para acessar a aplicacao (se estiver funcionando), execute:
echo minikube service minha-aplicacao
echo.
echo Se ainda houver problemas, execute:
echo kubectl describe pods
echo.

REM Iniciar o serviço em uma nova janela
echo Tentando iniciar o servico...
start cmd /k minikube service minha-aplicacao