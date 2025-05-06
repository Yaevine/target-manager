# Sistema de Gestor de Targets para CTF

## Motivo de la creación del script

Este script surgió por pura necesidad mientras practicaba con máquinas CTF en plataformas como TryHackMe. Me di cuenta de que estaba perdiendo mucho tiempo copiando y pegando direcciones IP, o peor aún, escribiéndolas manualmente una y otra vez. Esto se volvía especialmente molesto cuando tenía que trabajar con varias IPs al mismo tiempo, ya fuera por temas de pivoting o simplemente por estar analizando múltiples máquinas en paralelo.

Además, en muchas ocasiones necesitaba reutilizar esas mismas IPs constantemente, y no tenerlas organizadas ralentizaba bastante el flujo de trabajo. Así que decidí crear un pequeño sistema que me permitiera guardar, listar y reutilizar fácilmente las IPs desde la terminal. El objetivo era claro: ahorrar tiempo, evitar errores tontos y hacer que el día a día en los CTFs fuera un poco más cómodo y ágil.

---

## Descripción de cada función

### `settarget`

**¿Para qué sirve?**
Permite guardar una IP (y opcionalmente un alias) como un nuevo "target" que se puede reutilizar en el terminal. También establece la variable `$target` para que esté lista para usar en comandos como `nmap`, `ping`, etc.

**¿Por qué lo hice?**
Porque me cansé de copiar y pegar direcciones IP todo el rato. Quería un sistema donde pudiera escribir algo tipo `settarget 10.10.11.22 myweb` y automáticamente tener `$target` listo para usar, sabiendo que ese alias quedaba registrado.

---

### `listtargets`

**¿Para qué sirve?**
Muestra todos los targets guardados en el sistema, con su IP, alias (si tiene), y el nombre de la variable (`$target0`, `$target1`, etc.).

**¿Por qué lo hice?**
Cuando tengo varias máquinas en paralelo o estoy haciendo pivoting, necesito ver de un vistazo rápido todas las IPs guardadas. También es útil para saber si una IP ya estaba registrada o si puedo reutilizar un alias.

---

### `cleantargets`

**¿Para qué sirve?**
Elimina todos los targets guardados y limpia tanto el entorno como el archivo `targets.env`.

**¿Por qué lo hice?**
Cuando termino con una máquina (o con varias), me gusta tener el entorno limpio, sin variables sueltas o IPs que ya no sirven. Esta función deja todo como nuevo para empezar otra vez sin residuos.

---

### `usetarget`

**¿Para qué sirve?**
Permite seleccionar una IP ya guardada (por número, alias o IP) y establecerla como la actual `$target`.

**¿Por qué lo hice?**
Muchas veces guardaba varias IPs pero luego quería volver a una en concreto sin volver a escribirla. Con esta función puedo hacer algo como `usetarget 1` o `usetarget pivot1` y recuperar la IP de forma rápida.

---

## Integración en `.zshrc` y sincronización entre terminales

Cuando empecé a trabajar con este sistema de gestión de targets, me encontré con varios problemas que fui resolviendo poco a poco para lograr que todo funcionara de forma fluida y automática. Uno de los puntos clave fue la integración con Zsh, ya que quería que el sistema funcionara en todas las pestañas del terminal sin tener que hacer nada manual.

### Problemas iniciales que resolví

* **Las variables no estaban disponibles en nuevas pestañas**

  * Al principio, el sistema funcionaba bien solo en la pestaña donde había hecho `source targets.env`. Si abría otra terminal, las variables como `$target` no estaban definidas, y tenía que ejecutar algo manualmente para cargarlas.

* **Intenté hacerlo con `precmd` solo, pero no era suficiente**

  * Probé primero cargarlas justo antes del prompt (`precmd`), pero si ejecutaba un comando directamente tras abrir la terminal (sin esperar al prompt), las variables aún no estaban listas. Por eso añadí también el hook `preexec`.

* **Necesidad de sincronización continua entre terminales**

  * Si cambiaba algo en una terminal (por ejemplo, definía un nuevo target), quería que eso se reflejara automáticamente en las demás sin tener que escribir `source` a mano en cada una. El sistema de hooks se encarga de eso.

* **Limpieza automática si se borra `targets.env`**

  * También añadí una limpieza automática: si el archivo `targets.env` no existe, las variables se eliminan del entorno para evitar datos antiguos o confusión.

Este bloque en `.zshrc` es clave para que todo el sistema funcione de manera transparente y sin intervención manual. Al principio parecía innecesario, pero tras varias pruebas descubrí que era la única forma que encontré de asegurarme de que las variables estuvieran siempre disponibles y actualizadas en cualquier momento.

---

## Estructura del Proyecto

El proyecto está pensado para ser simple, modular y accesible desde cualquier terminal. Todos los scripts están ubicados en `~/bin/`, que se añade al `PATH` para poder ejecutarlos desde cualquier directorio.

```bash
~/bin/
├── target_functions.sh  # Contiene todas las funciones: settarget, listtargets, cleantargets, usetarget
~/targets.env            # Archivo generado automáticamente que guarda los targets actuales
```

---

## Ejemplos prácticos

### `settarget`

Guarda una IP como `$target` y la añade a la lista de targets.

```bash
# Ejemplo sin alias:
settarget 10.10.100.5

# Ejemplo con alias:
settarget 10.10.100.5 pivote1
```

---

### `listtargets`

Muestra todos los targets guardados:

```bash
Target actual: 10.10.100.5 (alias: pivote1)

target0: 10.10.100.5 (alias: pivote1)
target1: 10.10.200.7 (alias: web1)
target2: 192.168.1.12 (sin alias)
```

---

### `usetarget`

Cambia el `$target` actual fácilmente:

```bash
# Por número:
usetarget 1

# Por alias:
usetarget web1
```

---

### `cleantargets`

Borra todos los targets guardados:

```bash
cleantargets
```

---

## Agradecimiento final

Este proyecto no nació como algo grande ni complejo, simplemente como una herramienta para hacerme la vida más fácil durante mis prácticas diarias con máquinas de CTF, pentesting y labs como TryHackMe, HackTheBox, etc. Sin embargo, con el tiempo fue creciendo poco a poco, añadiendo funciones según las necesidades que iban surgiendo: cambiar de target fácilmente, tener un entorno limpio después de terminar una máquina, recordar qué IP corresponde a qué alias sin tener que tirar de memoria, etc.

Hoy por hoy, este pequeño sistema se ha vuelto una parte esencial de mi flujo de trabajo. Me permite centrarme en lo importante y olvidarme de repetir tareas mecánicas una y otra vez. Y aunque no es perfecto, lo uso todos los días y me ha ahorrado muchísimo tiempo y frustración.

Ojalá este sistema os resulte tan útil como a mí. Si os sirve para mejorar vuestra productividad, evitar errores tontos o simplemente trabajar con más orden, entonces habrá cumplido su objetivo.

Estoy completamente abierto a sugerencias, ideas, mejoras o correcciones. Siempre estoy aprendiendo, y cualquier feedback será más que bienvenido.

Gracias por leer
