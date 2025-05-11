@echo off
REM filepath: c:\Repos\Estudos\GprcProject\k8\baixar-imagens-minikube.bat
echo ============== DOWNLOAD DE IMAGENS PARA MINIKUBE OFFLINE ==============

REM Definir versão do Kubernetes (ajuste conforme sua versão instalada)
set K8S_VERSION=v1.24.0
echo Versao do Kubernetes a ser usada: %K8S_VERSION%

REM Criar diretório para armazenar as imagens se não existir
if not exist ".\imagens" mkdir ".\imagens"

echo.
echo === Baixando imagens base do Minikube ===
echo.

REM Base do Minikube
docker pull gcr.io/k8s-minikube/kicbase:v0.0.46
docker save -o .\imagens\kicbase.tar gcr.io/k8s-minikube/kicbase:v0.0.46

echo.
echo === Baixando imagens principais do Kubernetes ===
echo.

REM Imagens principais do Kubernetes
docker pull registry.k8s.io/kube-apiserver:%K8S_VERSION%
docker pull registry.k8s.io/kube-controller-manager:%K8S_VERSION%
docker pull registry.k8s.io/kube-scheduler:%K8S_VERSION%
docker pull registry.k8s.io/kube-proxy:%K8S_VERSION%
docker pull registry.k8s.io/pause:3.7
docker pull registry.k8s.io/etcd:3.5.3-0
docker pull registry.k8s.io/coredns/coredns:v1.8.6

REM Salvar imagens principais
docker save -o .\imagens\kube-apiserver.tar registry.k8s.io/kube-apiserver:%K8S_VERSION%
docker save -o .\imagens\kube-controller-manager.tar registry.k8s.io/kube-controller-manager:%K8S_VERSION%
docker save -o .\imagens\kube-scheduler.tar registry.k8s.io/kube-scheduler:%K8S_VERSION%
docker save -o .\imagens\kube-proxy.tar registry.k8s.io/kube-proxy:%K8S_VERSION%
docker save -o .\imagens\pause.tar registry.k8s.io/pause:3.7
docker save -o .\imagens\etcd.tar registry.k8s.io/etcd:3.5.3-0
docker save -o .\imagens\coredns.tar registry.k8s.io/coredns/coredns:v1.8.6

echo.
echo === Baixando imagens para addons ===
echo.

REM Metrics Server
docker pull registry.k8s.io/metrics-server/metrics-server:v0.6.1
docker save -o .\imagens\metrics-server.tar registry.k8s.io/metrics-server/metrics-server:v0.6.1

REM Dashboard (opcional)
docker pull kubernetesui/dashboard:v2.6.1
docker pull kubernetesui/metrics-scraper:v1.0.8
docker save -o .\imagens\dashboard.tar kubernetesui/dashboard:v2.6.1
docker save -o .\imagens\metrics-scraper.tar kubernetesui/metrics-scraper:v1.0.8

echo.
echo === Criando arquivo de carregamento de imagens ===
echo.

REM Criar script para carregar as imagens
echo @echo off > carregar-imagens.bat
echo echo Carregando imagens para minikube... >> carregar-imagens.bat
echo. >> carregar-imagens.bat
echo docker load -i .\imagens\kicbase.tar >> carregar-imagens.bat
echo docker load -i .\imagens\kube-apiserver.tar >> carregar-imagens.bat
echo docker load -i .\imagens\kube-controller-manager.tar >> carregar-imagens.bat
echo docker load -i .\imagens\kube-scheduler.tar >> carregar-imagens.bat
echo docker load -i .\imagens\kube-proxy.tar >> carregar-imagens.bat
echo docker load -i .\imagens\pause.tar >> carregar-imagens.bat
echo docker load -i .\imagens\etcd.tar >> carregar-imagens.bat
echo docker load -i .\imagens\coredns.tar >> carregar-imagens.bat
echo docker load -i .\imagens\metrics-server.tar >> carregar-imagens.bat
echo docker load -i .\imagens\dashboard.tar >> carregar-imagens.bat
echo docker load -i .\imagens\metrics-scraper.tar >> carregar-imagens.bat
echo. >> carregar-imagens.bat
echo echo Carregando imagens no minikube... >> carregar-imagens.bat
echo. >> carregar-imagens.bat
@REM echo minikube image load gcr.io/k8s-minikube/kicbase:v0.0.46 >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/kube-apiserver:%K8S_VERSION% >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/kube-controller-manager:%K8S_VERSION% >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/kube-scheduler:%K8S_VERSION% >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/kube-proxy:%K8S_VERSION% >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/pause:3.7 >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/etcd:3.5.3-0 >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/coredns/coredns:v1.8.6 >> carregar-imagens.bat
@REM echo minikube image load registry.k8s.io/metrics-server/metrics-server:v0.6.1 >> carregar-imagens.bat
@REM echo minikube image load kubernetesui/dashboard:v2.6.1 >> carregar-imagens.bat
@REM echo minikube image load kubernetesui/metrics-scraper:v1.0.8 >> carregar-imagens.bat
@REM echo. >> carregar-imagens.bat
@REM echo echo Todas as imagens foram carregadas! >> carregar-imagens.bat

@REM echo.
@REM echo === Instruções para uso offline ===
@REM echo.
@REM echo Para usar as imagens em um ambiente offline:
@REM echo 1. Copie a pasta "imagens" e o arquivo "carregar-imagens.bat" para o ambiente offline
@REM echo 2. Execute "carregar-imagens.bat" antes de iniciar o minikube
@REM echo 3. Inicie o minikube com o comando:
@REM echo    minikube start --driver=docker --cpus=2 --memory=4096 --cache-images=true
@REM echo.
@REM echo Download de imagens concluído!