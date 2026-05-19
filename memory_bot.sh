#!/bin/bash

# Configuration
THRESHOLD=85       # Seuil d'utilisation de la mémoire en %
CHECK_INTERVAL=60  # Intervalle de vérification en secondes
LOG_FILE="/var/log/memory_bot.log"

# Fonction de nettoyage (extraite de optimize_memory.sh)
optimize_now() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Mémoire haute détectée. Lancement de l'optimisation..." >> "$LOG_FILE"
    
    # Synchroniser les disques
    sync
    
    # Vider les caches
    echo 3 > /proc/sys/vm/drop_caches
    
    # Compacter la mémoire si disponible
    if [ -f /proc/sys/vm/compact_memory ]; then
        echo 1 > /proc/sys/vm/compact_memory
    fi
    
    # Gestion du Swap
    SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        SWAP_USED=$(free -m | awk '/^Swap:/{print $3}')
        MEM_AVAIL=$(free -m | awk '/^Mem:/{print $7}')
        if [ "$SWAP_USED" -lt "$MEM_AVAIL" ]; then
            swapoff -a && swapon -a
        fi
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Optimisation terminée." >> "$LOG_FILE"
}

echo "Démarrage du Bot d'Optimisation Mémoire (Seuil: ${THRESHOLD}%)" >> "$LOG_FILE"

while true; do
    # Calcul de l'utilisation de la mémoire
    # Utilisation % = (Total - Disponible) / Total * 100
    MEM_DATA=$(free | grep Mem:)
    TOTAL=$(echo $MEM_DATA | awk '{print $2}')
    AVAIL=$(echo $MEM_DATA | awk '{print $7}')
    
    USED_PERCENT=$(( 100 * ($TOTAL - $AVAIL) / $TOTAL ))
    
    if [ "$USED_PERCENT" -ge "$THRESHOLD" ]; then
        optimize_now
    fi
    
    sleep "$CHECK_INTERVAL"
done
