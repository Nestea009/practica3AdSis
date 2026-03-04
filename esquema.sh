#!/bin/bash
#
# practica_3.sh
# Administración de Sistemas - Práctica 3
#

############################################
# 1. Comprobación de privilegios
############################################
if [ "$EUID" -ne 0 ]; then
    echo "Este script necesita privilegios de administracion"
    exit 1
fi

############################################
# 4. Comprobación número de parámetros
############################################
if [ "$#" -ne 2 ]; then
    echo "Número incorrecto de párametros"
    exit 1
fi

OPCION="$1"
FICHERO="$2"

############################################
# 3. Validación opción
############################################
if [[ "$OPCION" != "-a" && "$OPCION" != "-s" ]]; then
    echo "Opción inválida" >&2
    exit 1
fi

############################################
# Comprobación existencia fichero
############################################
if [ ! -f "$FICHERO" ]; then
    exit 1
fi

############################################
# 6. Configuración fichero log
############################################
FECHA=$(date +"%Y_%m_%d")
LOG="${FECHA}_user_provisioning.log"

############################################
# 18. Crear directorio backup si -s
############################################
if [ "$OPCION" == "-s" ]; then
    mkdir -p /extra/backup
fi

############################################
# Procesamiento fichero
############################################
while IFS=',' read -r USER PASS FULLNAME
do

    ########################################
    # AÑADIR USUARIOS
    ########################################
    if [ "$OPCION" == "-a" ]; then

        # 9. Validar campos no vacíos
        if [ -z "$USER" ] || [ -z "$PASS" ] || [ -z "$FULLNAME" ]; then
            echo "Campo invalido"
            exit 1
        fi

        # 8. Si usuario ya existe
        if id "$USER" &>/dev/null; then
            MENSAJE="El usuario $USER ya existe"
            echo "$MENSAJE"
            echo "$MENSAJE" >> "$LOG"
            continue
        fi

        ####################################
        # 12. Calcular UID >= 1815
        ####################################
        LAST_UID=$(awk -F: '$3>=1815 {print $3}' /etc/passwd | sort -n | tail -1)
        if [ -z "$LAST_UID" ]; then
            NEW_UID=1815
        else
            NEW_UID=$((LAST_UID+1))
        fi

        ####################################
        # 12,13,14 Crear usuario
        ####################################
        useradd -m \
                -k /etc/skel \
                -U \
                -u "$NEW_UID" \
                -c "$FULLNAME" \
                "$USER"

        ####################################
        # 11. Establecer contraseña
        ####################################
        echo "$USER:$PASS" | chpasswd

        ####################################
        # 7. Caducidad 30 días
        ####################################
        chage -M 30 "$USER"

        MENSAJE="$FULLNAME ha sido creado"
        echo "$MENSAJE"
        echo "$MENSAJE" >> "$LOG"

    fi

    ########################################
    # BORRAR USUARIOS
    ########################################
    if [ "$OPCION" == "-s" ]; then

        # 5. Solo necesario USER
        if [ -z "$USER" ]; then
            continue
        fi

        # 10. Si no existe, continuar
        if ! id "$USER" &>/dev/null; then
            continue
        fi

        HOME_DIR=$(eval echo "~$USER")

        ####################################
        # 17. Backup antes de borrar
        ####################################
        if [ -d "$HOME_DIR" ]; then
            tar -cf "/extra/backup/${USER}.tar" -C "$HOME_DIR" . 2>/dev/null
            if [ "$?" -ne 0 ]; then
                continue
            fi
        fi

        ####################################
        # 16. Borrado completo
        ####################################
        userdel -r "$USER"

    fi

done < "$FICHERO"

exit 0