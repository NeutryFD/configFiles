# NeutryArch

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
* To hability swap storage
  ~~~
  #swapon 
  ~~~
### Mont partitions just created
*
