#!/bin/bash


betterlockscreen(){

##  --- INFO ------------------
echo -e "
 Betterlockscreen Information:

    Dependencies:

     [+] i3lock-color 
     [+] xorg-xdpyinfo
     [+] imagemagick 
     [+] xorg-xrandr 
     [+] bc
    
    Repository URL: https://github.com/betterlockscreen/betterlockscreen \n
	"
	sleep 3
##  --- Installation ----------
   
echo -e "[*] Init Installation..."
   sudo pacman -S i3lock-color xorg-xrandr xorg-xdpyinfo imagemagick bc -y

echo -e "\n[*] Creating symbolic link..."

   mkdir -p ~/.config/betterlockscreen/
   ln -sf   $(pwd)/betterlockscreen/betterlockscreenrc 	$HOME/.config/betterlockscreen/
   
 
echo -e "\n[*] Usage: betterlockscreen -u \${PAHT_TO_IMAGE}"

}

betterlockscreen
