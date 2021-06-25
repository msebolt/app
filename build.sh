#!/bin/bash
source="on" #on|off
boot="disk" #iso|disk

drive="/dev/sda"
drived="" #p
partuuid=$(blkid -o export "${drive}${drived}"2 | grep PARTUUID)

password="" #temp1234
user_name="bit"
user_password="temp1234"

#min="linux syslinux mkinitcpio edk2-shell efibootmgr gptfdisk vim iwd wayland" #wayfire labwc-git hikari dwl
client="nano vim mkinitcpio syslinux linux iwd git parted xf86-video-intel arch-install-scripts b43-fwcutter bind-tools broadcom-wl btrfs-progs clonezilla crda darkhttpd ddrescue diffutils dmraid dosfstools edk2-shell efibootmgr ethtool exfat-utils f2fs-tools fsarchiver gnu-netcat gpm gptfdisk grml-zsh-config haveged hdparm irssi jfsutils kitty-terminfo lftp linux-atm linux-firmware lsscsi lvm2 lynx man-db man-pages mc mdadm mkinitcpio-archiso mkinitcpio-nfs-utils mtools nbd ndisc6 nfs-utils nilfs-utils nmap ntfs-3g nvme-cli openconnect openvpn partclone partimage ppp pptpclient reflector reiserfsprogs rp-pppoe rxvt-unicode-terminfo sdparm sg3_utils smartmontools sudo systemd-resolvconf tcpdump terminus-font termite-terminfo testdisk usb_modeswitch usbutils vpnc wireless-regdb wireless_tools wvdial xfsprogs xl2tpd zsh alsa-utils archiso cmake dhcp dialog hostapd hwloc libmicrohttpd mesa mime-types ntp wget onboard openbox lxde-common lxdm lxsession xorg-server xorg-xhost xorg-xinit xorg-xinput xorg-xrandr xterm feh chromium code openscad scons inkscape gimp blender musescore openshot"
#wayland sway
server="haproxy certbot rsync python python-pip"
python="aiohttp asyncio av aiortc opencv-python aiosmtpd"

timezone=""
host="bitos"

wifi_adapter=$(echo $(ls -d /sys/class/net/w*) | sed 's/\/sys\/class\/net\///g')
wifi_id=""
wifi_password=""

client_ip="192.168.1.126"
dev_ip=""
prod_ip=""

action="setup" #setup|deploy

base() {
    parted -s ${drive} mklabel gpt mkpart primary fat32 1 300M mkpart primary ext2 300M 100% set 1 esp on

    mkfs.vfat ${drive}${drived}1
    mkfs.ext4 ${drive}${drived}2

    mount ${drive}${drived}2 /mnt
    mkdir /mnt/boot
    mount ${drive}${drived}1 /mnt/boot

    if [[ "${source}" == "on" ]]
    then
        pacstrap /mnt base base-devel
    elif [[ "${source}" == "off" ]]
    then
        cp -ax / /mnt
        rm /mnt/etc/fstab
    fi

    if [[ "${boot}" == "disk" ]]
    then
        cp -vaT /boot /mnt/boot
    elif [[ "${boot}" == "iso" ]]
    then
        cp -vaT /run/archiso/bootmnt/arch/boot/$(uname -m)/vmlinuz-linux /mnt/boot/vmlinuz-linux
        cp /run/archiso/bootmnt/shellx64.efi /mnt/boot/shellx64.efi
        cp -r /run/archiso/bootmnt/EFI /mnt/boot/EFI
        cp /run/archiso/bootmnt/arch/boot/amd-ucode.img /mnt/boot/amd-ucode.img
        cp /run/archiso/bootmnt/arch/boot/intel-ucode.img /mnt/boot/intel-ucode.img
        cp -r /run/archiso/bootmnt/loader /mnt/boot/loader
    fi

    genfstab -U /mnt >> /mnt/etc/fstab
    
    cp "$0" /mnt/root/build.sh
    rsync config /mnt
    #sync config files...?
    if [[ "${source}" == "on" ]]
    then
        arch-chroot /mnt /root/build.sh install
    elif [[ "${source}" == "off" ]]
    then
        arch-chroot /mnt /root/build.sh boot
    fi

    umount /mnt/boot
    umount /mnt
}

install() {
    pacman -Sy --noconfirm pacman-mirrorlist
    pacman -Syy
    pacman -Syu
    pacman -Sy --noconfirm ${client}

    chmod +x /usr/bin/bitos
    systemctl enable bitos.service

    menu
    pip install ${python}

    useradd -m -g users -G wheel ${user_name} # passwd -d $USER_NAME, if root install/from git is needed
    echo -en "${password}\n${password}" | passwd
    echo -en "${user_password}\n${user_password}" | passwd ${user_name}
    echo "${user_name} ALL=(ALL:ALL) ALL" >> /etc/sudoers
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

    systemctl enable systemd-resolved
    systemctl enable systemd-networkd
    systemctl enable iwd

    cat > /etc/systemd/network/20-wireless.network <<EOF
Address=${ip}
EOF
    iwctl --passphrase ${wifi_password} station ${wifi_adapter} connect ${wifi_id} #optional, for wireless

    mv /usr/bin/lxpolkit /usr/bin/lxpolkit.bak

    #sync config files...
    chmod +x /usr/bin/bitl
    echo "@sh /usr/bin/bitl" >> /etc/xdg/lxsession/LXDE/autostart
    # switch to xfce? lxde changed to qt... #https://wiki.archlinux.org/title/dwm

    boot
}

boot() {
    hostnamectl set-hostname ${host}

    mv /boot/loader/entries/archiso-x86_64-linux.conf /boot/loader/entries/archiso-x86_64-linux.conf.old

    mv /boot/syslinux/syslinux.cfg /boot/syslinux/syslinux.cfg.old

    sed -i "s/root=XXXX/root=${partuuid}/g" /boot/loader/entries/archiso-x86_64-linux.conf
    sed -i "s/root=XXXX/root=${partuuid}/g" /boot/syslinux/syslinux.cfg

    mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.old

    mkinitcpio -P
    syslinux-install_update -i -a -m
}

client() {
    ssh-keygen -t rsa -b 4096 -C me@you.com
    openssl ecparam -genkey -name secp384r1 | openssl ec -out ecc-privkey.pem
    #rsync -a /root/msebolt/deploy root@<ip>:~
    tar -czvf name-of-archive.tar.gz /path/to/directory-or-file
    scp file.txt username@to_host:/remote/directory/
    ssh-agent bash -c 'ssh-add /somewhere/yourkey; /root/build.sh server'
}

server() {
    tar -czvf name-of-archive.tar.gz /path/to/directory-or-file
    tar -xzvf archive.tar.gz

    if [[ "${action}" == "setup" ]]
    then
        echo "Port 22" >> /etc/ssh/sshd_config
        echo "AllowUsers ${user_name}" >> /etc/ssh/sshd_config
        #add public key to /home/user/.ssh/authorized_keys
        #enable PubKey authentication in /etc/ssh/sshd_config (restart service)
        systemctl enable sshd

        pacman -Sy --overwrite \* ${server}
        pip3 install ${python}

        #echo "localhost  dralun.com" >> /etc/hosts
    elif [[ "${action}" == "deploy" ]]
    then
        killall -9 run.py
        systemctl stop haproxy
    fi

    #Edit /etc/ssl/openssl.cnf (change domains at end of file)
    openssl req -new -sha256 -key ecc-privkey.pem -nodes -outform pem -out ecc-csr.pem
    certbot certonly -w /root/cert -d abder.us -d www.abder.us --email pot@ladl.co --csr ecc-csr.pem --agree-tos --non-interactive --standalone
    sudo -E bash -c 'cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/haproxy/certs/$DOMAIN.pem'
    #sync haproxy... #set processors, use 'lscpu' #.../etc/letsencrypt/live/bitl.co/fullchain.pem
    systemctl start haproxy
    exec nohup python /root/deploy/deploy/run.py > /dev/null 2>&1 & disown &
}

if [[ "$1" == "install" ]]
then
    install
elif [[ "$1" == "boot" ]]
then
    boot
elif [[ "$1" == "client" ]]
then
    client
elif [[ "$1" == "server" ]]
then
    server
else
    base
fi

#certbot certonly --email matt@sebolt.us --csr ecc-csr.pem --agree-tos --non-interactive --standalone

#(0)
#-d nfnth.com -d mattdown.com -d dralun.com -d ur.land -d roland.rest -d lond.in

#(100)
#-d abder.us -d absaroka.us -d acebasin.us -d achomawi.us -d addams.us -d agamenticus.us -d agassiz.us -d agiocochook.us -d ahjumawi.us -d ahupua.us -d aiguebelle.ca -d alagnak.us -d alapaha.us -d albermarle.us -d alenuihaha.us -d aleutian.us -d alibate.us -d alibates.us -d allapattah.us -d alligatorriver.us -d aloalo.us -d altamaha.us -d altoona.us -d angelou.us -d angolabay.us -d aniakchak.us -d antiloch.us -d apalachicola.us -d apopka.us -d appleblossom.us -d arapaho.us -d arecibo.us -d arikara.us -d armistead.us -d assabet.us -d assateague.us -d atchafalaya.us -d athabaska.ca -d attakapas.us -d aucilla.us -d aulavik.ca -d babcockranch.us -d badriver.us -d baldmountain.us -d baltimoreoriole.us -d bandelier.us -d banksisland.ca -d bannecker.us	-d baranof.us -d bardeen.us -d bashakill.us -d battlecreek.us -d baydunorde.ca -d belleplain.us -d belmore.us -d bemidji.us -d bennitt.us -d beringland.us -d bhander.in -d bhimgad.in -d bierstadt.us -d bigbald.us -d bigbelt.us -d bigoaks.us -d bigsioux.us -d bigthick.us -d bigthicket.us -d biloxistate.us -d birchmountains.ca -d blackbutte.us -d blackfeet.us -d blacksusan.us -d bladenlake.us -d bladenlakes.us	-d bluecypress.us -d blurgrass.us -d boisblanc.us -d boisforte.us -d bombayhook.us -d borglum.us -d boulter.us -d bowermaster.us -d brahmagiri.in -d brasstownbald.us -d brazoria.us -d brazos.us -d brices.us -d bridgerteton.us -d bristleconepine.us -d brooking.us -d brownpelican.us -d brownthrash.us -d bruleriver.us -d bullcreek.us -d bunkerhill.us -d cabbagepalmetto.us -d cabonga.ca -d cactuswren.us -d cahokia.us

#(200)
#-d californiapoppy.us -d canavera.us -d canyonland.us -d capitolpeak.us -d capitolreef.us -d capoppy.us -d capulin.us -d carrituck.us -d carystate.us -d cather.us -d cedarbreak.us -d centla.mx -d chacahua.mx -d chamizal.us -d chandoli.in -d charlotteharbor.us -d chassahowitzka.us -d cheaha.us -d cheboygan.us -d chena.us -d chengwatana.us -d chequamegon.us -d cherokeerose.us -d cheybogan.us -d cheyenneriver.us -d chillicothe.us -d chiricahua.us -d choctawhatchee.us -d chpaaqn.us -d chukachida.ca -d churncreek.ca -d chuska.us -d clatsop.us -d cleghorn.us -d cobscook.us -d cockaponset.us -d colville.us -d commonloon.us -d conchas.mx -d conecuh.us -d congaree.us -d corinth.us -d cornhusker.us -d cotigao.in -d cratermoon.us -d croatan.us -d crowcreek.us -d cruces.us -d cumgap.us -d curecanti.us -d custergallatin.us -d cutlercoast.us -d dalene.us -d dalles.us -d damwash.us -d danboon.us -d deathcanyon.us -d debsconeag.us -d deltona.us -d denetiah.ca -d deslacs.us -d desot.us		 -d desotonational.us -d devilslake.us -d dismal.us -d dismalswamp.us -d dispoint.us -d donelson.us -d douglasfir.us -d drytortugas.us -d duckmountain.ca -d ducktrap.us -d duckvalley.us -d dunezakeyih.ca -d easthemlock.us -d eastpine.us -d eastredbud.us -d edgehills.ca -d edziza.ca -d escanaba.us -d esselen.us -d estacado.us -d evergladesnational.us -d fairstone.us -d fairystone.us -d fakahatchee.us -d faneuil.us -d feynman.us -d fishring.us -d flambeau.us -d flaptop.us -d flintrock.us -d floridapanther.us -d florissant.us -d flycatcher.us -d fortbelknap.us -d fortberthold.us -d fortcobb.us -d fortcuster.us 

#(300)
#-d fortpeck.us -d fortpickens.us -d fortstanton.us -d fourche.us -d fourcorner.us -d francismarion.us -d frankchurch.us -d frankenhaler.us		 -d frederica.us -d frenchcreek.us -d frenchman.ca -d frenchman.us -d friedan.us -d frissell.us -d fuca.us -d gangokri.in -d gardengod.us -d gatearctic.us -d gaudens.us -d gauley.us -d gilariver.us -d gipsylake.ca -d gitnadoiks.ca -d glacialridge.us -d glencanyon.us -d goethestate.us -d goldenrod.us -d goldwyn.us -d gompers.us -d gorda.mx -d gorgeana.us -d goshute.us -d governors.us -d grandbahama.us -d grandfork.us -d grandisland.us -d grandstair.us -d grandstaircase.us -d gravecreek.us -d greatsand.us -d greatswamp.us -d greatwren.us -d greenswamp.us -d grouse.us -d grylls.us -d guayama.us -d gullrock.us -d hakalau.us -d halelea.us -d hartwickpine.us -d hassam.us -d havre.us -d headley.us -d heartisland.us -d heeia.us -d henrycoe.us -d hermitthrush.us -d heyerdahl.us	-d hidatsa.us -d holeyland.us -d hollyshelter.us -d homathko.ca -d homochitto.us -d honorat.us -d honouliuli.us -d hoopa.us -d hovenweep.us -d huautla.mx -d humacao.us -d hurston.us -d ibapah.us -d internationalpeace.us -d islandred.us -d isleroyale.us -d isulijarnik.ca -d ivvavik.ca -d jackhall.us	 -d jamestowne.us -d jenningsstate.us -d jerimoth.us -d jessamine.us -d jonathandickinson.us -d justinhurst.us -d jwcorbett.us -d kabetogama.ca -d kabetogama.us -d kabinakagami.ca -d kachemak.us -d kaena.us -d kahikinui.us -d kahuku.us -d kaibab.us -d kalae.us -d kalapana.us -d kalaupapa.us -d kaloko.us -d kaniksu.us -d kapapala.us -d katannilik.ca -d kaula.us

#(400)
#-d kaulakahi.us -d keahole.us -d keaiwa.us -d keeffe.us -d kenaifjords.us -d kenilworth.us -d kenogami.ca -d kenridge.us -d keokuk.us -d khutzeymateen.ca -d kianuko.ca -d killdevil.us -d kingscanyon.us -d kipahoehoe.us -d kisatchie.us -d kissimmeechain.us -d kissimmeeprairie.us -d klamathmarsh.us -d kobuk.us -d koochiching.us -d koolau.us -d kooning.us	-d kootenai.us -d kosciuszko.us -d kotgarh.in -d krusenstern.us -d kuaokala.us -d kumiva.us -d kwadacha.ca -d kwolek.us	-d lacassine.us -d lagartos.mx -d laketraverse.us -d landlake.us -d langtang.in -d larkbunting.us -d lavabed.us -d leechlake.us -d leelanau.us -d leutze.us	-d lewisclark.us -d lichenstein.us -d lihue.us -d limbaugh.us -d lindbergh.us -d lorrainemotel.us -d lospadres.us -d losttrail.us -d mackinac.us -d mahoosuc.us -d malheur.us -d malloryswamp.us -d malpais.us -d mandan.us -d mant.us -d marblerange.ca -d matagorda.us -d matanzas.us -d mattamuskeet.us -d mattatuck.us -d maxhamish.us -d mcfaddin.us -d mehatl.ca -d midewin.us -d missinaibi.ca -d mississagi.ca -d missouria.us -d mockorange.us -d mogollon.us -d mohican.us -d mohonk.us -d mokuleia.us -d moloaa.us -d monocacy.us -d monongahela.us -d monongohela.us -d moosehorn.us -d morgancity.us -d morro.us -d moshannon.us -d mountainlaurel.us -d mquqwin.ca -d mukilteo.us -d muncie.us -d muscovite.ca -d muskingum.us -d myakka.us -d naatsichoh.ca -d nagagamisis.ca -d naismith.us -d nampa.us -d nanj.in -d nantahala.us -d narrowhills.ca -d nashstream.us -d naturalbridge.us -d negwegon.us -d nehantic.us -d nelchina.us -d neosho.us 

#(500)
#-d neuse.us -d nezperce.us	-d niiinliinjik.ca -d nimpkish.ca -d ningunsaw.ca -d niobrara.us -d noatak.us -d nopiming.ca -d northcheyenne.us -d northoak.us -d nueces.us -d nunivak.us -d obispo.us -d ocalanational.us -d ocmulgee.us -d ogoki.ca -d ohiobuckeye.us -d oilcity.us -d okaloacoochee.us -d okanogan.us -d okefenokee.us -d oldwife.ca -d oldwives.ca -d oleopry.us -d oologah.us -d opasquia.ca -d orangeblossum.us -d oregongrape.us -d oregontrail.us -d organpipe.us -d osceola.us -d ossabaw.us -d otoe.us -d ouachita.us -d pachaug.us -d paeonia.us -d paiute.us -d palpur.in -d pamlico.us -d pantanos.mx -d paperbirch.us -d paracut.in -d parashant.us -d pascagoula.us -d pasqueflower.us -d passamaquoddy.us -d patos.us -d pawnee.us -d payette.us -d paynesprarie.us -d peacegarden.us -d peachblossum.us -d peary.us -d pfeifferbigsur.us -d pharaohlake.us -d picayunestrand.us -d pinchot.us -d pinebluff.us -d pinelemoray.ca -d pingualuit.ca -d pinkrhododendron.us -d plumas.us -d pocomoke.us -d pocono.us -d ponderosapine.us -d poplarbluff.us -d porthuron.us -d portsmith.us -d prairierose.us -d presque.us -d priestley.us -d prudhoe.us -d ptarmigan.us -d pukaskwa.ca -d pupukea.us -d purplefinch.us -d purplelilac.us -d purpleviolet.us -d puuhonua.us -d puukohola.us -d pynchon.us -d quehanna.us -d quinault.us -d quittinirpaaq.ca -d redden.us -d redlake.us -d richloam.us -d rioranch.us -d ritablanca.us -d rivergorge.us -d riverlakes.us -d robcreek.us -d rochambeau.us -d rockycolumbine.us -d roscommon.us -d rotenberger.us -d rydell.us -d sacagawea.us -d saguarocactus.us -d salinger.us 

#(600)
#-d salmonchallis.us -d samish.us -d sanbernard.us -d sanblas.us -d sandhill.us -d sandlakes.ca -d santee.us -d sapelo.us -d scarletcarnation.us -d schlissel.us -d schunnemunk.us -d scottkey.us -d sebastianriver.us -d sebolt.us -d segolily.us -d sepultura.mx -d servi.us -d seul.ca -d sheyenne.us -d shimek.us -d shippen.us -d shoolpaneshwar.in -d shrinedemocracy.us -d shuksan.us -d shuyak.us -d shypoke.us -d simsbury.us -d siouxfall.us -d sirmilik.ca -d siskiyou.us -d sitbull.us -d sitgreaves.us -d sittingbull.us -d siuslaw.us -d sixflag.us -d sixrivers.us -d skymeadows.us	 -d sloancanyon.us -d smokeymountain.us -d smokyhill.us -d snakeriver.us -d spatsizi.ca -d sproul.us -d standingrock.us -d standrock.us -d stanislaus.us -d stanwix.us -d steamtown.us -d sugarmaple.us -d sunkland.us -d susquehanna.us -d susquehannock.us -d sustut.ca -d szilard.us -d tahquamenon.us -d tahsishkwois.ca -d talladega.us -d talquin.us -d tatehell.us -d tateshell.us -d tatlatui.ca -d tatlayoko.ca -d taumsauk.us -d tenement.us -d texoma.us -d threelakes.us -d thunderbasin.us -d tigerbay.us -d timpanogos.us -d timucuan.us -d tobyhanna.us -d tohakum.us -d tohono.us -d tohonoodham.us -d tongass.ca -d tosohatchee.us -d tsilos.ca -d tsitka.ca -d tubman.us -d tuktut.ca -d tumacacori.us -d turon.mx -d turtlemountain.us -d turtleriver.ca -d tutuaca.mx -d tuzigoot.us -d uinta.us -d uintah.us -d umpqua.us -d unalaska.us -d uncompahgre.us -d upolu.us -d utemountain.us -d uwharrie.us -d valleyquail.us -d vermilioncliff.us -d verrazzano.us -d vespucci.us -d vincennes.us 

#(700)
#-d voyageurs.us -d vuntut.ca -d wabash.us -d waccasassa.us -d wagonroad.us -d wahiawa.us -d waiahole.us -d waiakea.us -d waikoloa.us -d wailua.us -d wakeforest.us -d walkriver.us -d walkwater.us -d wallowa.us -d waquoit.us -d warmspring.us -d watauga.us -d weirfarm.us -d westhemlock.us -d westminister.us -d westtwin.ca -d whiskeytown.us -d whitebutte.us -d whiteearth.us -d whitefishbay.us -d whiteriver.us -d whitesand.us -d whitespruce.us	-d willamette.us -d winisk.ca -d witchita.us -d wompatuck.us -d woodlandcaribou.ca -d woodviolet.us -d wrangell.ca -d wupatki.us -d xingtai.us -d yampa.us -d yamsay.us -d yawal.in -d yellowjessamine.us -d yellowpoplar.us -d yuccaflower.us -d yunque.us -d zuni.us

#(800)=778
#-d tactician.us
beausejour.us		

bellefamille.us
beuport.us

bloodcreek.us
	
cacapon.us
	
codiac.us
flatts.us
	
fortbull.us
fortniagara.us
frontenac.us
jumonville.us
	
ligonier.us

louisbourg.us
lunenberg.us
oswego.us
	
petitcodiac.us
plassey.us
	
restigouche.us
saintefoy.us
	
schinske.us
sideling.us
snowshoe.us
theroux.us
trembles.us		

trough.us

#bash -c 'cat 0000_cert.pem 0001_cert.pem 0002_cert.pem 0003_cert.pem 0004_cert.pem 0005_cert.pem 0006_cert.pem ecc-privkey.pem > /etc/haproxy/certs/multi.pem'

#statemap.us, bitstat.us, localstat.us, jakant.com, katank.com, rolynd.com, civilplex.com, drhab.com, sloeg.in, victoryg.in, pygish.com
