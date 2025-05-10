@echo off
echo ============== IMPLANTACAO NO KUBERNETES (MODO OFFLINE) ==============

REM 1. Parar o Minikube existente (caso exista)
echo Parando Minikube existente...
minikube stop

REM 2. Iniciar o Minikube com configurações para funcionar offline
echo Iniciando Minikube com configuracoes para modo offline...
minikube start --driver=docker --cpus=2 --memory=4096 --image-mirror-country=cn --insecure-registry="10.0.0.0/24" --cache-images=true

REM 3. Habilitar o Metrics Server para o auto-escalamento
echo Habilitando o Metrics Server...
minikube addons enable metrics-server

REM 4. Configurar ambiente para o Docker no Minikube
echo Configurando ambiente para usar Docker no Minikube...
FOR /F "tokens=*" %%i IN ('minikube -p minikube docker-env --shell cmd') DO %%i

REM 5. Informar sobre a imagem Docker que será usada
minikube image load vitorpadovan/gprcvitor:latest
echo Usando a imagem Docker: vitorpadovan/gprcvitor:latest

REM 6. Verificar se a imagem está disponível localmente
echo Verificando disponibilidade da imagem localmente...
docker images | findstr "vitorpadovan/gprcvitor" >nul
if %ERRORLEVEL% NEQ 0 (
    echo Imagem nao encontrada localmente. Tentando baixar...
    docker pull vitorpadovan/gprcvitor:latest
    if %ERRORLEVEL% NEQ 0 (
        echo ERRO: Nao foi possivel baixar a imagem. Certifique-se de ter a imagem disponivel localmente.
        exit /b 1
    )
)

REM 7. Criar tag da imagem para uso com o Minikube
echo Criando tag da imagem para uso com o Minikube...
docker tag vitorpadovan/gprcvitor:latest minikube/gprcvitor:latest

REM 8. Aplicar os manifestos
echo Aplicando os manifestos Kubernetes...
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

REM 9. Aguardar a criação dos pods
echo Aguardando a criacao dos pods (30 segundos)...
kubectl get pods
echo Aguardando...
timeout /t 30 /nobreak

REM 10. Verificar status
echo Verificando o status da implantacao...
kubectl get pods
kubectl get services
kubectl get hpa

REM 11. Se os pods não estiverem em execução, tentar correção
FOR /F "tokens=*" %%p IN ('kubectl get pods -o jsonpath^="{.items[0].status.phase}" 2^>nul') DO (
    set POD_STATUS=%%p
)
if NOT "%POD_STATUS%"=="Running" (
    echo Os pods nao estao em execucao. Tentando corrigir...
    
    FOR /F "tokens=*" %%n IN ('kubectl get pods -o jsonpath^="{.items[0].metadata.name}"') DO (
        set POD_NAME=%%n
    )
    
    echo Descricao do pod %POD_NAME%:
    kubectl describe pod %POD_NAME%
    
    kubectl describe pod %POD_NAME% | findstr "ErrImagePull ImagePullBackOff" >nul
    if %ERRORLEVEL% EQU 0 (
        echo Problema com a imagem detectado. Tentando abordagem alternativa...
        
        echo Criando Dockerfile temporario...
        echo FROM vitorpadovan/gprcvitor:latest > Dockerfile.temp
        
        echo Construindo imagem localmente...
        docker build -t offline-app:latest -f Dockerfile.temp .
        
        echo Atualizando deployment para usar imagem local...
        kubectl set image deployment/minha-aplicacao minha-aplicacao=offline-app:latest
        
        echo Forcando politica de pull para Never...
        kubectl patch deployment minha-aplicacao -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"minha-aplicacao\",\"imagePullPolicy\":\"Never\"}]}}}}"
        
        echo Aguardando mais 30 segundos...
        timeout /t 30 /nobreak
        
        echo Verificando status apos correcao...
        kubectl get pods
    )
)

REM 12. Túnel para acessar a aplicação
echo Para acessar sua aplicacao, execute em outro terminal:
echo minikube service minha-aplicacao

REM 13. Instruções adicionais
echo Implantacao concluida!
echo Para monitorar o auto-escalamento, execute: kubectl get hpa minha-aplicacao --watch
echo Para testar o auto-escalamento, você pode gerar carga com:
echo kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://minha-aplicacao; done"

REM 14. Iniciar o serviço automaticamente
echo Iniciando o servico em uma nova janela...
start cmd /k minikube service minha-aplicacao