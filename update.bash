#!/bin/bash

#func
detect_package_manager() {
    if command -v apt >/dev/null; then
        echo "apt"
    elif command -v dnf >/dev/null; then
        echo "dnf"
    elif command -v pacman >/dev/null; then
        echo "pacman"
    elif command -v zypper >/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

detect_flatpak() {
    if command -v flatpak >/dev/null; then
        echo true
    else
        echo false
    fi
}

detect_snap() {
    if command -v snap >/dev/null; then
        echo true
    else
        echo false
    fi
}


#abfrage ob der User root ist
if [[ $EUID -ne 0 ]]; then
   echo "Moment mal, Kumpel! Du musst dieses Skript als Root ausführen, sonst verweigert mein System den Dienst."
   echo "Versuch's mal mit: sudo $0"
   exit 1
fi

SYSTEM=$(uname -s)
HOSTNAME=$(hostname)
PACKAGE_MANAGER=$(detect_package_manager)
FLATPAK_INSTALLED=$(detect_flatpak)
SNAP_INSTALLED=$(detect_snap)
COMMAND_LINE="-> "

echo "Möchtest du den dein $SYSTEM auf $HOSTNAME System neue Pakete bestellen? [J/N]"
read -p "$COMMAND_LINE" -r
echo 

if [[ $REPLY =~ ^[nN]$ ]]; then
    echo "Auf WiederUpdaten!"
    exit 0
fi

#wenn kein Pakete Manager erkannt wurde... Opfer 
#natürtlich nur spaß :P 
if [ "$PACKAGE_MANAGER" == "unknown" ]; then
    echo "Uhm... ich konnte keinen bekannten Paketmanager finden. Bist du sicher, dass das hier Linux ist?"
    exit 1
fi

echo "Dein Lieferprozess wird beginnen..."
sleep 1
echo " "

case "$PACKAGE_MANAGER" in
    "apt")
        echo "Deine Apt Pakete werden bestellt..."
        sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
        ;;
    "dnf")
        echo "Deine DNF Pakete werden bestellt..."
        sudo dnf update -y && sudo dnf autoremove -y
        ;;
    "pacman")
        echo "Deine Apt Pacman werden bestellt c. C. c. C. c."
        sudo pacman -Syu --noconfirm
        sudo pacman -Qtdq | sudo pacman -Rns -
        ;;
    "zypper")
        echo "Deine Zypper Pakete werden bestellt..."
        sudo zypper refresh && sudo zypper update -y && sudo zypper autoremove -y
        ;;
    *)
        echo "Es konnten keine Pakete von ($PACKAGE_MANAGER) bestellt werden.."
        ;;
esac

#flatpak update
if $FLATPAK_INSTALLED; then
    echo "2. Flatpak Pakete werden geliefert.."
    if flatpak update; then
        echo "Flatpak Packete sind abgestellt worden."
    else
        echo "Die Flatpak Packete konnten nicht zugestellt werden."
        exit 1
    fi
    echo " "
else
    echo "Du hast kein Flatpak..."
fi

#snap update
if $SNAP_INSTALLED; then
    echo "3. Snap Pakete werden geliefert.."
    if snap refresh; then
        echo "Snap Packete sind abgestellt worden."
    else
        echo "Die Snap Packete konnten nicht"
        exit 1
    fi
    echo " "
else
    echo "Du hast kein Snap..."
fi



#Neustart abfrage
echo "Alles ist an Ort und Stelle!" #wir sind ja nicht dpd oder deutsche post oder hermes :/
echo "Möchtest du das System jetzt neu starten? [J/N]"
read -p "$COMMAND_LINE" -r
echo 
if [[ $REPLY =~ ^[jJ]$ ]]; then
    echo "Okay, starte neu! Bis gleich, ich halt dir die Tür auf..."
    reboot
else
    echo "Okay dann kein Neustart dann AufWiederUpdaten!"
    exit 0
fi