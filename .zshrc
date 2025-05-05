# Cargamos los targets definidos si existe el archivo
[ -f ~/targets.env ] && source ~/targets.env

# Añadimos ~/bin al PATH para poder usar los scripts desde cualquier lugar
export PATH="$HOME/bin:$PATH"

# Cargamos las funciones relacionadas con la gestión de targets
source ~/bin/target_functions.sh

# SIncronización automatica al ejecutar comandos o mostrar prompt
autoload -Uz add-zsh-hook

refresh_targets() {
  if [ -f ~/targets.env ]; then
    source ~/targets.env
  else
    # Limpiar todas las variables target si no existe el archivo
    unset target
    for i in {0..30}; do
      unset "target$i"
    done
  fi
}
add-zsh-hook precmd refresh_targets   # Antes del prompt
add-zsh-hook preexec refresh_targets  # Antes de ejecutar un comando
