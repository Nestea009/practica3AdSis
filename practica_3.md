# Informe Práctica 3 – Administración de Sistemas

**898447, Alejaldre Martin, Hector, M, 3, B**

**926915, Blanco Ramos, Nestor, M, 3, B**

## Decisiones de diseño

### Comprobación de privilegios

Se comprueba si el usuario pertenece al grupo `sudo` mediante `id -nG`. Si no pertenece,
se muestra el mensaje requerido y se termina con código de salida 1. Esto permite que el
script sea ejecutado con `sudo` por el usuario `as`, que tiene acceso sin contraseña en
la máquina virtual al sudo.

### Fichero de log

El nombre del log sigue el formato `YYYY_MM_DD_<usuario>_provisioning.log`. Se genera
con `date +"%Y_%m_%d"` y `whoami`. Si el fichero no existe, se crea con `touch`; si ya
existe, los mensajes se añaden con `>>` sin sobreescribir el contenido previo.

### Lectura del fichero de entrada

Se usa un bucle `while IFS=',' read -r USER PASS FULLNAME` para leer los campos separados por coma. En el caso de la opción `-s`, solo se usa el campo `USER` y los demás se ignoran con `_`. 

El uso de `IFS=','` asegura que los campos se separen correctamente, incluso si el nombre completo contiene espacios.
La cláusula `|| [ -n "$USER" ]` garantiza que la última línea se procesa aunque no
termine en salto de línea.

### Creación de usuarios (`-a`)

- Se comprueba la existencia previa del usuario con `id`. Si ya existe, se informa y se
  continúa con el siguiente.
- Se valida que los tres campos (usuario, contraseña y nombre completo) sean no vacíos
  antes de proceder.
- El UID se calcula leyendo el último UID de `/etc/passwd` con `tail` y `cut`. Si es
  menor que 1815, se asigna directamente 1815; en caso contrario, se incrementa en 1.
- Se usa `useradd -m -k /etc/skel -u <uid> -U -c "<nombre completo>"` para crear el
  usuario con home inicializado desde `/etc/skel` y grupo propio del mismo nombre (`-U`).
- La contraseña se establece con `chpasswd` y la caducidad a 30 días con `chage -M 30`.

### Borrado de usuarios (`-s`)

- Se crea el directorio `/extra/backup` con `mkdir -p` al inicio del bloque, cumpliendo
  el requisito de que exista aunque no se borre ningún usuario.
- Solo se lee el primer campo (nombre de usuario); los demás son ignorados con `_`.
- Antes del borrado se genera un backup del directorio home con
  `tar -cf /extra/backup/<usuario>.tar -C /home <usuario>`.
- Si el comando `tar` falla (código de salida distinto de 0), no se realiza el borrado
  y se continúa con el siguiente usuario.
- El borrado se realiza con `userdel -r`, que elimina también el directorio home.
- Si el usuario no existe, se omite silenciosamente (sin mensaje ni entrada en el log),
  tal como indica el requisito 10.

### Gestión de errores y salidas

Para los siguientes errores, se ha optado por hacer las siguientes acciones:

- Argumentos incorrectos: mensaje por stdout y `exit 1`.
- Opción no reconocida: mensaje por stderr (`>&2`) y `exit 1`.
- El script termina siempre con `exit 0` al finalizar correctamente.
