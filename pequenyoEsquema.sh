#!/bin/bash

# Parámetros: $1: {-a|-s}, $2: <nombre_fichero>

# Comprobación de permisos
#if [[ "$EUID" -ne 0 ]]
#then
#    echo "Este script necesita privilegios de administracion" 
#    exit 1
#fi

# Comprobación de parámetros
if [ "$#" -ne 2 ]
then
    echo "Número incorrecto de parámetros"
    exit 1
fi

OPCION=$1
FICHERO=$2

# Comprobar archivo de log
FECHA=$(date +"%Y_%m_%d")
USUARIO=$(whoami)

dir_destino=$(ls "$FECHA"_"$USUARIO"_provisioning.log 2>/dev/null)

if [ -z "$dir_destino" ]
then
    touch "$FECHA"_"$USUARIO"_provisioning.log
    dir_destino=$(ls "$FECHA"_"$USUARIO"_provisioning.log 2>/dev/null)
fi

if [ "$OPCION" = "-a" ]
then
# Añadir
    while IFS=',' read -r USER PASS FULLNAME
    do

        if ([ -z "$USER" ] || [ -z "$PASS" ] || [ -z "$FULLNAME" ] )
        then
            echo "Campo invalido"
            echo "Campo invalido" >> "$dir_destino"
            continue
        fi

        if  id "$USER" &>/dev/null 
        then
            MENSAJE="El usuario $USER ya existe"
            echo "$MENSAJE"
            echo "$MENSAJE" >> "$dir_destino"
            continue
        fi

        uid=$(tail -n 1 /etc/passwd | cut -d: -f3)

            if [ "$uid" -ge 1815 ]; then
                nuevo_uid=$((uid + 1))
            else
                nuevo_uid=1815
            fi
        
        /usr/sbin/useradd -m -k /etc/skel -u "$nuevo_uid" -U -c "$FULLNAME" "$USER"

        # Contraseña caduca en 30 días
        # Si se ha creado, escribir por pantalla el nombre completo y "ha sido creado"
        # Si el usuario ya existe, escribir por pantalla "El usuario <nombre_usuario> ya existe" y escribirlo también en el log

    done < "$FICHERO"

elif [ "$OPCION" = "-s" ]
then
# Suprimir

    while IFS=',' read -r USER
    do

    # HAY QUE IGNORAR EL PASS Y EL FULLUSERNAME
        echo "Suprimir $USER"

    done < "$FICHERO"

# Comprobación de opción
else
    echo "Opción inválida" >&2
    exit 1
fi




exit 0

# COMO COMPILAR:
# No sé porqué pero no deja ejecutar con sh pequenyoEsquema.sh
# Pero sí que va con ./pequenyoEsquema -a fichero.txt
# Haciendo antes un chmod +x pequenyoEsquema


# Reqisitos:

    # Crear usuarios con useradd, chpasswd

    # UID ≥ 1815

    # Grupo con el mismo nombre

    # Home creado con /etc/skel

    # Caducidad de contraseña 30 días

    # Registrar acciones en log

    # Comprobar si usuario existe

    # Backup antes de borrar en /extra/backup

    # Borrado con userdel -r

    # Usar tar para backup