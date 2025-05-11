REM 12. Verificar status
echo Verificando o status da implantacao...
kubectl get pods
kubectl get services
kubectl get hpa

REM 13. Se os pods não estiverem em execução, tentar correção
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
        echo FROM %DOCKER_IMAGE%:latest > Dockerfile.temp
        
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

REM 14. Túnel para acessar a aplicação
echo Para acessar sua aplicacao, execute em outro terminal:
echo minikube service minha-aplicacao

REM 15. Instruções adicionais
echo Implantacao concluida!
echo Para monitorar o auto-escalamento, execute: kubectl get hpa minha-aplicacao --watch
echo Para testar o auto-escalamento, você pode gerar carga com:
echo kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://minha-aplicacao; done"

REM 16. Iniciar o serviço automaticamente
echo Iniciando o servico em uma nova janela...
start cmd /k minikube service minha-aplicacao