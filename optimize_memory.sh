#!/bin/bash

# Configuration des couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Récupération de l'utilisateur réel (si lancé avec sudo)
REAL_USER=${SUDO_USER:-$USER}

# Fonction de nettoyage de la mémoire
optimize_now() {
    if [[ $EUID -ne 0 ]]; then echo -e "${RED}Erreur : Root requis.${NC}"; return; fi
    echo -e "\n${BLUE}--- Nettoyage de la Mémoire (Ponctuel) ---${NC}"
    MEM_BEFORE=$(free -m | awk '/^Mem:/{print $3}')
    sync
    echo 3 > /proc/sys/vm/drop_caches
    if [ -f /proc/sys/vm/compact_memory ]; then echo 1 > /proc/sys/vm/compact_memory; fi
    SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        SWAP_USED=$(free -m | awk '/^Swap:/{print $3}')
        MEM_AVAIL=$(free -m | awk '/^Mem:/{print $7}')
        if [ "$SWAP_USED" -lt "$MEM_AVAIL" ]; then
            swapoff -a && swapon -a
        fi
    fi
    MEM_AFTER=$(free -m | awk '/^Mem:/{print $3}')
    echo -e "${GREEN}Terminé. Gain : $((MEM_BEFORE - MEM_AFTER)) Mo${NC}"
}

# Fonction de tuning système permanent
apply_tuning() {
    if [[ $EUID -ne 0 ]]; then echo -e "${RED}Erreur : Root requis.${NC}"; return; fi
    echo -e "\n${BLUE}--- Optimisation Permanente (Kernel Tuning) ---${NC}"
    update_sysctl() {
        sed -i "/^$1/d" /etc/sysctl.conf
        echo "$1 = $2" >> /etc/sysctl.conf
        sysctl -w $1=$2 > /dev/null
    }
    update_sysctl "vm.swappiness" "10"
    update_sysctl "vm.vfs_cache_pressure" "50"
    update_sysctl "vm.dirty_ratio" "10"
    update_sysctl "vm.dirty_background_ratio" "5"
    echo -e "${GREEN}Réglages permanents appliqués !${NC}"
}

# Fonction pour réparer l'espacement des icônes (Cinnamon/Nemo)
fix_desktop_spacing() {
    echo -e "\n${BLUE}--- Réparation de l'espacement du Bureau ---${NC}"
    # On utilise des valeurs plus fortes pour que le changement soit visible
    # Et on redémarre Nemo pour forcer le rafraîchissement du bureau
    sudo -u $REAL_USER gsettings set org.nemo.desktop vertical-grid-adjust 1.5
    sudo -u $REAL_USER gsettings set org.nemo.desktop horizontal-grid-adjust 1.3
    
    echo -n "Rafraîchissement du bureau... "
    sudo -u $REAL_USER nemo -q
    echo -e "${GREEN}OK${NC}"
    
    echo -e "${GREEN}Espacement augmenté et bureau rafraîchi !${NC}"
}

# Fonction d'installation du Bot
install_bot() {
    if [[ $EUID -ne 0 ]]; then echo -e "${RED}Erreur : Root requis.${NC}"; return; fi
    echo -e "\n${BLUE}--- Installation du Bot d'Optimisation ---${NC}"
    
    chmod +x "$(dirname "$0")/memory_bot.sh"
    cp "$(dirname "$0")/memory-bot.service" /etc/systemd/system/
    
    # Mise à jour du chemin dans le service si nécessaire
    sed -i "s|ExecStart=.*|ExecStart=/bin/bash $(realpath "$(dirname "$0")/memory_bot.sh")|" /etc/systemd/system/memory-bot.service
    
    systemctl daemon-reload
    systemctl enable memory-bot.service
    systemctl start memory-bot.service
    
    echo -e "${GREEN}Bot installé et démarré !${NC}"
    echo -e "Les logs sont disponibles dans : ${YELLOW}/var/log/memory_bot.log${NC}"
}

# Menu Principal
clear
echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}   OPTIMISEUR DE PERFORMANCE DARKMEDIA-X   ${NC}"
echo -e "${BLUE}===========================================${NC}"
echo -e "1) ${GREEN}Nettoyage immédiat${NC} (RAM + Swap)"
echo -e "2) ${YELLOW}Optimisation permanente${NC} (Kernel/Système)"
echo -e "3) ${BLUE}Réparer l'espacement du Bureau${NC} (Icônes)"
echo -e "4) ${GREEN}Tout appliquer${NC}"
echo -e "5) ${YELLOW}Installer/Démarrer le Bot automatique${NC}"
echo -e "q) Quitter"
echo -e "${BLUE}-------------------------------------------${NC}"
read -p "Votre choix : " choice

case $choice in
    1) optimize_now ;;
    2) apply_tuning ;;
    3) fix_desktop_spacing ;;
    4) optimize_now; apply_tuning; fix_desktop_spacing ;;
    5) install_bot ;;
    q) exit 0 ;;
    *) echo -e "${RED}Choix invalide.${NC}" ;;
esac

echo -e "\n${BLUE}Appuyez sur Entrée pour fermer...${NC}"
read
