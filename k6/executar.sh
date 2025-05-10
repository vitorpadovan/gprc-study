#!/bin/bash

# Define uma única vez o timestamp
timestamp=$(date +%Y-%m-%d_%H-%M-%S)

# Cria a pasta com o timestamp
mkdir -p ./resultados/$timestamp

# Executa o K6 com os arquivos de saída usando o mesmo timestamp
k6 run script.js \
  --summary-export=./resultados/$timestamp/summary_$timestamp.json \
  > ./resultados/$timestamp/output_$timestamp.log \
  2> ./resultados/$timestamp/outputerr_$timestamp.log
