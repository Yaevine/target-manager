#!/bin/bash

TARGET_FILE="$HOME/targets.env"

# =========================
# Función para establecer un nuevo target
settarget() {
    local IP="$1"
    local ALIAS="$2"

    # Verifica que se haya pasado al menos una IP
    if [ -z "$IP" ]; then
      echo "Uso: settarget <IP> [alias]"
      return 1
    fi

    # Verifica formato básico de IP válida (0-255)
    if ! [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      echo "Formato de IP inválido: $IP"
      return 1
    fi
    for octet in $(echo "$IP" | tr '.' ' '); do
        if (( octet > 255 )); then
            echo "IP inválida: $IP (octeto > 255)"
            return 1
        fi
    done

    TARGETS_FILE="$HOME/targets.env"
    touch "$TARGETS_FILE"

    # --- Verificar si la IP ya está registrada ---
    if grep -qE "^export target[0-9]+=\"$IP\"" "$TARGETS_FILE"; then
      EXISTING_LINE=$(grep -E "^export target[0-9]+=\"$IP\"" "$TARGETS_FILE")
      EXISTING_VAR=$(echo "$EXISTING_LINE" | cut -d'=' -f1)
      EXISTING_INDEX=$(echo "$EXISTING_VAR" | sed 's/export target//')
      EXISTING_ALIAS=$(grep -E "^export alias${EXISTING_INDEX}=" "$TARGETS_FILE" | cut -d'=' -f2- | tr -d '"')
      echo "La IP $IP ya está registrada como ${EXISTING_VAR} (alias: ${EXISTING_ALIAS:-<sin alias>})"
      return 1
    fi

    # --- Si hay alias, verificar que no esté repetido ---
    if [ -n "$ALIAS" ]; then
      if grep -qE "^export alias[0-9]+=\"$ALIAS\"" "$TARGETS_FILE"; then
        EXISTING_ALIAS_LINE=$(grep -E "^export alias[0-9]+=\"$ALIAS\"" "$TARGETS_FILE")
        EXISTING_INDEX=$(echo "$EXISTING_ALIAS_LINE" | sed 's/^export alias\([0-9]\+\)=.*/\1/')
        EXISTING_IP=$(grep "^export target${EXISTING_INDEX}=" "$TARGETS_FILE" | cut -d'=' -f2- | tr -d '"')
        echo "El alias $ALIAS ya está en uso para la IP $EXISTING_IP"
        return 1
      fi
    fi

    # --- Encontrar el siguiente índice libre ---
    local index=0
    while grep -q "^export target$index=" "$TARGETS_FILE"; do
        index=$((index + 1))
    done

    # --- Guardar la IP y alias (si hay) ---
    echo "export target$index=\"$IP\"" >> "$TARGETS_FILE"
    echo "export alias$index=\"${ALIAS:-}\"" >> "$TARGETS_FILE"

    # Actualizar el target actual
    sed -i '/^export target="/d' "$TARGETS_FILE"
    sed -i '/^export target_alias="/d' "$TARGETS_FILE"
    echo "export target=\"$IP\"" >> "$TARGETS_FILE"
    echo "export target_alias=\"${ALIAS:-}\"" >> "$TARGETS_FILE"

    source "$TARGETS_FILE"

    echo "Target $IP guardado como \$target$index"
    if [ -n "$ALIAS" ]; then
      echo "Alias: $ALIAS"
    fi
}
# =========================
# Función para cambiar el target actual
usetarget() {
    local input="$1"
    local ip=""
    local alias=""
    local found=0

    if [[ "$input" =~ ^[0-9]+$ ]]; then
        ip=$(grep "^export target$input=" "$TARGET_FILE" | cut -d'=' -f2- | tr -d '"')
        alias=$(grep "^export alias$input=" "$TARGET_FILE" | cut -d'=' -f2- | tr -d '"')
        found=1
    else
        local i=0
        while true; do
            local current_ip=$(grep "^export target$i=" "$TARGET_FILE" | cut -d'=' -f2- | tr -d '"')
            [ -z "$current_ip" ] && break
            local current_alias=$(grep "^export alias$i=" "$TARGET_FILE" | cut -d'=' -f2- | tr -d '"')
            if [ "$current_alias" = "$input" ]; then
                ip="$current_ip"
                alias="$current_alias"
                found=1
                break
            fi
            i=$((i + 1))
        done
    fi

    if [ "$found" -eq 0 ] || [ -z "$ip" ]; then
        echo "Target no encontrado: $input"
        return 1
    fi

    # Actualiza el target actual: elimina las líneas previas y agrega las nuevas
    sed -i '/^export target="/d' "$TARGET_FILE"
    sed -i '/^export target_alias="/d' "$TARGET_FILE"
    echo "export target=\"$ip\"" >> "$TARGET_FILE"
    echo "export target_alias=\"$alias\"" >> "$TARGET_FILE"

    source "$TARGET_FILE"

    echo "Target cambiado a: $target ($target_alias)"
}

# =========================
# Función para listar todos los targets
listtargets() {
    if [ ! -f "$TARGET_FILE" ]; then
        echo "No hay targets guardados."
        return
    fi

    local index=0
    local found=0

    echo "Targets guardados:"
    while true; do
        local line=$(grep "^export target$index=" "$TARGET_FILE")
        if [ -z "$line" ]; then
            break
        fi
        local ip=$(echo "$line" | cut -d'=' -f2- | tr -d '"')
        local alias_line=$(grep "^export alias$index=" "$TARGET_FILE")
        local alias=$(echo "$alias_line" | cut -d'=' -f2- | tr -d '"')
        echo "[$index] $ip (alias: $alias)"
        index=$((index + 1))
        found=1
    done

    if [ "$found" -eq 1 ]; then
        echo "Target actual: ${target:-No definido}"
        echo "Alias actual: ${target_alias:-No definido}"
    else
        echo "No hay targets guardados."
    fi
}

# =========================
# Función para limpiar todos los targets
clean_targets() {
    [ -f "$TARGET_FILE" ] && rm "$TARGET_FILE"

    local i=0
    while [ $i -lt 100 ]; do
        unset "target$i"
        unset "alias$i"
        i=$((i + 1))
    done

    unset target
    unset target_alias

    echo "Targets limpiados correctamente."
    # Vuelve a cargar el archivo (estará vacío)
    [ -f "$TARGET_FILE" ] && source "$TARGET_FILE"
}

# =========================
# Al cargar el archivo, se exportan las variables de TARGET_FILE al entorno actual.
if [ -f "$TARGET_FILE" ]; then
    source "$TARGET_FILE"
fi
