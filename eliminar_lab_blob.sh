#!/bin/bash

RG="rg-blob-seguro"

echo "Eliminando grupo de recursos $RG..."
az group delete --name $RG --yes --no-wait
