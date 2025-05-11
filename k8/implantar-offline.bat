@echo off
cls;

set DOCKER_IMAGE=vitorpadovan/gprc
echo ============== IMPLANTACAO NO KUBERNETES (MODO OFFLINE) ==============

echo Nome da imagem Docker: %DOCKER_IMAGE%

REM 1. Parar o Minikube existente (caso exista)
echo Parando Minikube existente...
minikube status | findstr "Running" >nul
if %ERRORLEVEL% EQU 0 (
    minikube stop
)

REM 2. Apagar imagem docker
echo Apagando imagem Docker...
docker images | findstr "%DOCKER_IMAGE%" >nul
if %ERRORLEVEL% EQU 0 (
    docker rmi %DOCKER_IMAGE%
)

REM 4. Iniciar o Minikube com configurações para funcionar offline
echo Iniciando Minikube com configuracoes para modo offline...
REM minikube start --driver=docker --cpus=2 --memory=4096 --image-mirror-country=us --insecure-registry="10.0.0.0/24" --cache-images=true
minikube start --driver=docker --cpus=2 --memory=4096 --cache-images=true

REM 7. Configurar ambiente para o Docker no Minikube
echo Configurando ambiente para usar Docker no Minikube...
FOR /F "tokens=*" %%i IN ('minikube -p minikube docker-env --shell cmd') DO %%i

REM 3. Gerar imagem Docker
echo Gerando imagem Docker...
docker build -t %DOCKER_IMAGE% -f ..\GprcProject\Dockerfile ..\

REM 10. Aplicar os manifestos
echo Aplicando os manifestos Kubernetes...
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
@REM kubectl apply -f hpa.yaml

REM 11. Aguardar a criação dos pods
echo Aguardando a criacao dos pods (30 segundos)...
kubectl get pods
echo Aguardando...
timeout /t 30 /nobreak

REM 12. Verificar status
echo Verificando o status da implantacao...
kubectl get pods
kubectl get services
kubectl get hpa

REM 16. Iniciar o serviço automaticamente
echo Iniciando o servico em uma nova janela...
start cmd /k minikube service minha-aplicacao
