
## Git Started (with software of inifinitive-basis)

![software](https://github.com/msebolt/site/raw/main/1760745908.jpg)

1. Download [Arch Linux](http://mirror.rackspace.com/archlinux/iso/2021.06.01/archlinux-2021.06.01-x86_64.iso), then create an ISO, use either: 

   - command-line, `dd if=/path/to/archlinux.iso of=/usb/drive status=progress`, use `fdisk -l` to find the USB
   - [rufus](https://github.com/pbatard/rufus) *Windows*

1. Reboot into BIOS (press **Esc**, **Del**, or **F1..F12** on startup), then run:

   ```
   #iwd... #wifi only
   pacman -S git --noconfirm
   git clone https://github.com/msebolt/site
   vim site/build.sh  #press (i) to insert and make changes, (Esc) to escape, then either :wq (write quit) or :q (quit)
   ```

## IMPORTANT, BE SURE CORRECT PARAMETERS ARE SET, ELSE YOU CAN WIPE OUT THE WRONG DRIVE (see table)

|Parameter|Default|Description|
|-|-|-|
|disk|`/dev/sda`|Drive to install to.|
|diskpart|(empty)|Drive part, eg. `/dev/mmcblk0p1` has diskpart of `p`|
|ip|`192.168.1.111`|Default IP|
|user|`temp`|Default user|
|hash|`temp1234`|Generated hash used to sign in (password).|

That's it! To propagate as needed use `\build.sh server` with different parameter sets.

Visit `https://localhost` to get started with your site/app. Changes made can be kept in sync with `rsync`, for backups use `tar -xvzf ...`

(*optional*) use Linode in case of hardware failure or catastrophe

Enjoy!

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/-xMR_x3lYAA/0.jpg)](https://www.youtube.com/watch?v=-xMR_x3lYAA)

**Version 1.04**

   
1. Use SSH *optional*, get IP with `ip addr`, then set router and forward ports to:
|Port|Function|
|-|-|
|80|http|
|443|https|
|2525|mail|
|587|tls|

1. Run site, use backup/restore *optional*:
```
./build.sh site #adjust processors, use 'lscpu'
```

## How to install servius

Configure domains using **Google** [domain](https://domains.google.com) 

Setup router with the following ports:

|Port|Function|
|-|-|
|80|http|
|443|https|
|2525|mail|
|587|tls|

Install certs using: (also configure haproxy)
```
certbot certonly --standalone -d ${site}, cp -r /etc/letsencrypt/live/${site} data/${site}
sudo -E bash -c 'cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/haproxy/certs/$DOMAIN.pem'
```

Build a strack unit, attach an M.2 drive (enclosure) and run `servius/servos/install.sh old`. Deploy unit.

Go to site and setup user/password. Repeat build strack units for each additional and use add IP function.

### Additional commands

```
fdisk -l #show drives
df, ls -a, du -xhS | sort -h | tail -n15 #show file/folder info
lscpu #show hardware info
grep -R "term" #search

ip addr show #show network connections
ping google.com -c 2 #test network
```
