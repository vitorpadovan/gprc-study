# Guia de Resolução de Problemas - Kubernetes no Windows

## Problema: SVC_UNREACHABLE (Serviço não disponível)

Se você receber o erro: `Exiting due to SVC_UNREACHABLE: service not available: no running pod for service minha-aplicacao found`

### Soluções possíveis:

1. **Verifique se os pods estão em execução:**

   ```
   kubectl get pods
   ```

   Se os pods estiverem com status `Pending` ou `ImagePullBackOff`:

   ```
   kubectl describe pod [nome-do-pod]
   ```

2. **Problema de acesso à imagem Docker:**

   Se estiver usando uma imagem local:

   ```
   # Conecte o Docker daemon do seu WSL com o Minikube
   eval $(minikube -p minikube docker-env)

   # Reconstrua a imagem (se necessário)
   docker build -t sua-imagem:latest .

   # Reinicie o deployment
   kubectl rollout restart deployment minha-aplicacao
   ```

3. **Reiniciar tudo do zero:**

   ```
   # Excluir todos os recursos
   kubectl delete -f deployment.yaml -f service.yaml -f hpa.yaml

   # Parar e reiniciar o Minikube
   minikube stop
   minikube start --driver=docker --cpus=2 --memory=4096

   # Aplicar os manifestos novamente
   kubectl apply -f deployment.yaml -f service.yaml -f hpa.yaml
   ```

4. **Verificar integração WSL com Docker:**

   ```
   # No PowerShell (como admin)
   wsl --status
   docker context ls
   ```

   Certifique-se de que o Docker está configurado para usar o WSL.

5. **Usar o túnel do Minikube** (solução mais confiável):

   ```
   # Em uma janela de terminal separada
   minikube tunnel

   # Em outra janela
   kubectl port-forward service/minha-aplicacao 8080:80
   ```

   Agora você pode acessar o serviço em http://localhost:8080

## Problema: Pods não iniciam ou ficam em "Pending"

1. **Verifique os eventos do Kubernetes:**

   ```
   kubectl get events --sort-by='.lastTimestamp'
   ```

2. **Verifique os logs do pod:**

   ```
   kubectl logs [nome-do-pod]
   ```

3. **Verifique os detalhes do pod:**

   ```
   kubectl describe pod [nome-do-pod]
   ```

4. **Se for um problema de recursos:**

   Reduza as solicitações de recursos no arquivo `deployment.yaml`:

   ```yaml
   resources:
     requests:
       cpu: "50m"
       memory: "64Mi"
   ```

## Problema: Auto-escalamento não funciona

1. **Verifique se o Metrics Server está funcionando:**

   ```
   kubectl get apiservices | grep metrics
   ```

2. **Reinicie o addon:**

   ```
   minikube addons disable metrics-server
   minikube addons enable metrics-server
   ```

3. **Verifique se as métricas estão disponíveis:**
   ```
   kubectl top pods
   kubectl top nodes
   ```

## Dicas Gerais para Windows com WSL e Docker

1. **Certifique-se de que o WSL está atualizado:**

   ```
   wsl --update
   ```

2. **Use o Docker Desktop com integração WSL:**

   - Nas configurações do Docker Desktop, certifique-se de que a integração WSL está ativada

3. **Reinicie todos os serviços, se necessário:**

   ```
   # PowerShell (Admin)
   Restart-Service *docker*
   wsl --shutdown
   # Espere alguns segundos e inicie o WSL novamente
   wsl
   ```

4. **Minikube com driver específico:**

   ```
   minikube start --driver=docker
   ```

   Ou, se você tiver Hyper-V:

   ```
   minikube start --driver=hyperv
   ```
