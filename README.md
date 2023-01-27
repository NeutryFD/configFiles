# Parrot Security 

### Arch Instalation from bootable USB using manual instalation with terminal.

* Set your prefer keyboard language for comfortable , my case "es" (spanish)
~~~
#loadkeys es
~~~
### Patition that we need for install Arch
* Idenficate the storage devices in the pc using the command 
~~~
#fdisk -l 
~~~
* Select device to partition

~~~
#fdisk /dev/devive-selected
~~~
  select GPT patition type

* We will make three partition
  - Boot --> 512 M
  - System --> rest storage
  - Swap --> 5 GB
* Format the partition 
  - Boot
  ~~~

  ~~~
  - System
  ~~~
  #mkfs.ext4 /dev/system_partition
  ~~~
  - Swap
  ~~~
  #mkswap /dev/swap_partition
  ~~~
* To enable swap storage
~~~
#swapon 
~~~
### Mont partitions just created
  - Mount the partitin of the system
  ~~~
  #mount /dev/system_partition /mnt
  ~~~
  - Mont the boot partition
    - Create dicrectory for boot
    ~~~
    #mkdir /mnt/boot
    ~~~
  - Mont partition
  ~~~ 
  #mount /dev/partition_boot /mnt/boot
  ~~~
### Package instalation
~~~
#pacstrap -K /mnt base linux linux-firmware
~~~
### Create fstab ficher to auto-mount the partition at the start of the system
~~~
#genfstab -U /mnt >> /mnt/etc/fstab
~~~
### Go into our system 
~~~
#arch-chroot /mnt
~~~
### Alies usefull
~~~
#skill -kill - u {user} --> close sesion 
