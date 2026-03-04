#!/bin/bash

# Parámetros: $1: {-a|-s}, $2: <nombre_fichero>

# Comprobación de permisos
#if [[ "$EUID" -ne 0 ]]
#then
#    echo "Este script necesita privilegios de administracion" 
#    exit 1
#fi

# Comprobación de parámetros
if [[ "$#" -ne 2 ]]
then
    echo "Número incorrecto de parámetros"
    exit 1
fi

OPCION=$1
FICHERO=$2

# Comprobación de opción
if [[ ! "$OPCION" =~ ^(-a|-s)$ ]]
then
    echo "Opción inválida" <&2
    exit 1
fi

# Comprobar archivo de log
FECHA=$(date +"%Y_%m_%d")
USUARIO=$(whoami)

dir_destino=$(ls "$FECHA"_"$USUARIO"_provisioning.log 2>/dev/null)

if [[ -z "$dir_destino" ]]
then
    touch "$FECHA"_"$USUARIO"_provisioning.log
    dir_destino=$(ls "$FECHA"_"$USUARIO"_provisioning.log 2>/dev/null)
fi


