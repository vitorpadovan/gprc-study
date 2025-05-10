@echo off
echo Iniciando o processo de implantacao no Windows...

REM 1. Parar o Minikube existente (caso exista)
echo Parando Minikube existente...
minikube stop

REM 2. Iniciar o Minikube com driver correto
echo Iniciando Minikube...
minikube start --driver=docker --cpus=2 --memory=4096

REM 3. Habilitar o Metrics Server para o auto-escalamento
echo Habilitando o Metrics Server...
minikube addons enable metrics-server

REM 4. Informar sobre a imagem Docker que será usada
echo Usando a imagem Docker: vitorpadovan/gprcvitor:latest

REM 5. Aplicar os manifestos
echo Aplicando os manifestos Kubernetes...
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

REM 6. Aguardar a criação dos pods
echo Aguardando a criacao dos pods (30 segundos)...
kubectl get pods
timeout /t 30 /nobreak

REM 7. Verificar status
echo Verificando o status da implantacao...
kubectl get pods
kubectl get services
kubectl get hpa

REM 8. Informações para acesso
echo.
echo Implantacao concluida!
echo Para acessar sua aplicacao, execute em outro terminal:
echo minikube service minha-aplicacao
echo.
echo Para monitorar o auto-escalamento, execute:
echo kubectl get hpa minha-aplicacao --watch
echo.
echo IMPORTANTE: Se os pods nao estiverem em execucao, execute:
echo kubectl describe pod [nome-do-pod]
echo para verificar o problema.

REM 9. Iniciar o serviço automaticamente
echo.
echo Iniciando o servico em uma nova janela...
start cmd /k minikube service minha-aplicacao