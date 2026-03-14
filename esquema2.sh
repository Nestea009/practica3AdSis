#!/bin/bash

# practica_3.sh {-a|-s} <nombre_fichero>

#################################
# 1. Comprobación de privilegios
#################################
if [[ "$EUID" -ne 0 ]]; then
    echo "Este script necesita privilegios de administracion"
    exit 1
fi

#################################
# 2. Comprobación de parámetros
#################################
if [ "$#" -ne 2 ]; then
    echo "Número incorrecto de parámetros"
    exit 1
fi

OPCION="$1"
FICHERO="$2"

#################################
# 3. Comprobar fichero entrada
#################################
if [ ! -f "$FICHERO" ]; then
    echo "El fichero no existe"
    exit 1
fi

#################################
# 4. Preparar log
#################################
FECHA=$(date +"%Y_%m_%d")
USUARIO=$(whoami)
LOG="${FECHA}_${USUARIO}_provisioning.log"

touch "$LOG"

#################################
# Función obtener UID >=1815
#################################
get_next_uid() {
    awk -F: '$3>=1815 {print $3}' /etc/passwd | sort -n | tail -1 | awk '{print $1+1}'
}

#################################
# 5. Añadir usuarios
#################################
if [ "$OPCION" = "-a" ]; then

    while IFS=',' read -r USER PASS FULLNAME
    do

        # comprobar campos vacíos
        if [ -z "$USER" ] || [ -z "$PASS" ] || [ -z "$FULLNAME" ]; then
            echo "Campo invalido"
            exit 1
        fi

        # comprobar si usuario existe
        if id "$USER" &>/dev/null; then
            MENSAJE="El usuario $USER ya existe"
            echo "$MENSAJE"
            echo "$MENSAJE" >> "$LOG"
            continue
        fi

        get_next_uid() {
            awk -F: '$3>=1815 {print $3}' /etc/passwd | sort -n | tail -1 | awk '{print $1+1}'
        }

        NEW_UID=$(get_next_uid)

        /usr/sbin/useradd -m \
                        -k /etc/skel \
                        -u "$NEW_UID" \
                        -U \
                        -c "$FULLNAME" \
                        "$USER"

        if /usr/sbin/useradd -m -k /etc/skel -u "$NEW_UID" -U -c "$FULLNAME" "$USER"
        then
            echo "$USER:$PASS" | /usr/sbin/chpasswd
            /usr/bin/chage -M 30 "$USER"

            MENSAJE="$FULLNAME ha sido creado"
            echo "$MENSAJE"
            echo "$MENSAJE" >> "$LOG"
        fi

    done < "$FICHERO"

#################################
# 6. Suprimir usuarios
#################################
elif [ "$OPCION" = "-s" ]; then

    # crear directorio backup
    mkdir -p /extra/backup

    while IFS=',' read -r USER PASS FULLNAME
    do

        # ignorar líneas vacías
        if [ -z "$USER" ]; then
            continue
        fi

        # comprobar si usuario existe
        if ! id "$USER" &>/dev/null; then
            continue
        fi

        HOME_DIR="/home/$USER"
        BACKUP="/extra/backup/${USER}.tar"

        # realizar backup
        if [ -d "$HOME_DIR" ]; then

            /usr/bin/tar -cf "$BACKUP" -C /home "$USER"

            if [ $? -ne 0 ]; then
                # si falla backup no borrar
                continue
            fi
        fi

        # borrar usuario completamente
        /usr/sbin/userdel -r "$USER"

    done < "$FICHERO"

#################################
# 7. Opción inválida
#################################
else
    echo "Opción inválida" >&2
    exit 1
fi

exit 0