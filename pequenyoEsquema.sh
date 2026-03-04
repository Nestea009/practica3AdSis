#!/bin/bash

# Parámetros: $1: {-a|-s}, $2: <nombre_fichero>

if [[ "$#" -ne 2 ]]
then
    echo "Número incorrecto de parámetros"
    exit 1
fi

OPCION = $1
FICHERO = $2


