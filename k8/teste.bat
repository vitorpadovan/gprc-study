@echo off
cls
set DOCKER_IMAGE=gprcvitor
docker images | findstr "%DOCKER_IMAGE%"
@echo %ERRORLEVEL%
if %ERRORLEVEL% NEQ 0 (
    echo ERRO: Nao foi possivel encontrar a imagem %DOCKER_IMAGE% localmente.
    exit /b 1
)