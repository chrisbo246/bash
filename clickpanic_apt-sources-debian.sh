#!/bin/bash

. global.sh

distrib=$DIST
release=$PSUEDONAME

# Diese pour désactiver par défaut
nonfree='#'   # Non-free softwares
source='#'    # Sources codes for developers
unstable='#'  #
proposed='#'  # Pre-version softwares
testing='#'   # Betas
backports='#' # Non offical softwares

#cat > ${config_path}apt/sources.list <<EOF
cat > echo <<EOF

# How to import public key
# wget ${pubkeyurl}
# apt-key add pubkey
# gpg --import pubkey && gpg --fingerprint

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FREE - STABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### scenari
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#deb http://scenari-platform.org/deb $release main

### nerim-marillat
## Dépôts Nerim / Marillat pour le multimédia, site web, clef publique pour Synaptic
deb ftp://ftp.nerim.net/debian-marillat/ stable main

### juega-linex
## Dépôts Juega Linex, spécialiste des jeux libres
deb http://www.linex.org/sources/linex/debian/ cl juegalinex

### Wine
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#deb http://wine.budgetdedicated.com/apt $release main
$source deb-src http://wine.budgetdedicated.com/apt $release main

### wine-multimedia
## Alternative aux dépôts Nerim Marillat pour le multimedia et les jeux
deb http://wine.sourceforge.net/apt/ $release/

### ppc-multimedia
## Dépôt multimedia pour PowerPC (Mac)
deb http://honk.physik.uni-konstanz.de/~agx/linux-ppc/debian/ mplayer/

# DTC control panel
deb ftp://ftp.gplhost.com/debian stable main
$source deb-src ftp://ftp.gplhost.com/debian stable main

# ISPconfig
# Public key: http://www.dotdeb.org/dotdeb.gpg
deb http://packages.dotdeb.org stable all
$source deb-src http://packages.dotdeb.org stable all

# SysCP
# Public key: http://debian.syscp.org/pubkey
deb http://debian.syscp.org/ $release/
$source deb-src http://debian.syscp.org/ $release/

# Les dépôts PLF
# Il s’agit de dépôt légaux en France, mais litigieux dans certains pays (dont les Etats-unis), et qui ne sont donc pas intégrés dans les autres paquets pour ces raisons. On y retrouve :
#    * w32codecs : Codecs binaires nécessaires à la lecture de nombreuses vidéos AVI, DIVX, ...
#    * libdvdcss2 : Bibliothèque nécessaire à la lecture des DVD
#    * Skype : Le logiciel de VOIP le plus utilisé dans le monde
#    * divx4linux
#    * dir2ogg
#    * googleearth
#    * xmms-wma deb http://packages.freecontrib.org/ubuntu/plf/ dapper free non-free

deb http://ppa.launchpad.net/tualatrix/$distrib $release main
$source deb-src http://ppa.launchpad.net/tualatrix/$distrib $release main

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NON-FREE - STABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Pilotes wifi
#$nonfree deb http://ftp.de.debian.org/debian $release main non-free
#$nonfree deb-src http://ftp.de.debian.org/debian $release main non-free

# virtualbox
# Dépôts Virtual Box (Innotek)
$nonfree deb http://download.virtualbox.org/virtualbox/debian $release non-free

# google
# Dépôts Google
$nonfree deb http://dl.google.com/linux/deb/ stable non-free

### amd64
# Dépôt multimedia pour AMD 64 bits
$nonfree deb http://debian-amd64.alioth.debian.org/pure64 sid main contrib non-free

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FREE - UNSTABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### ati
# ATI Drivers pour XFree86 (pas très utile sous hoary, j'en conviens) ; paquets : netbrake, xfree86-ati.2, yydecode ; pour i386 et PPC
$unstable deb http://liyang.ucam.org/debian/ unstable main

### Eciadsl
# ECI ADSL Drivers par flashtux.org ; paquet : eciadsl-usermode
$unstable deb http://www.flashtux.org/debian unstable main

# Dépôt multimedia pour AMD 64 bits
$unstable deb http://cyberspace.ucla.edu/marillat/ unstable main

# Dépôt Debian pour Athlon X
$unstable deb http://mail.linuxvar.it/~gianluca/athlon-xp unstable main

### Debian
## Dépôts Debian officiels, utiliser avec prudence
$unstable deb ftp://ftp.debian.org/debian/ unstable main

### agnula-demudi-unstable
## Dépôts Agnula Demudi pour faire des expérimentations
$unstable deb http://freesoftware.ircam.fr/mirrors/demudi/ unstable main contrib

### nerim-marillat-unstable
## Dépôts Nerim / Marillat pour le multimédia, site web, clef publique pour Synaptic
$unstable deb ftp://ftp.nerim.net/debian-marillat/ unstable main

### geexbox
## Pleins de choses pour le multimédia
$unstable deb http://www.geexbox.org/debian/ unstable main

### rarewores
## Pleins de choses pour le multimédia
$unstable deb http://rarewares.soniccompression.com/debian/packages/unstable/ ./

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NON-FREE - UNSTABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### wine-unstable
## Pour avoir accès à la dernière version de wine
$nonfree deb http://jeroen.coekaerts.be/debian/ unstable main contrib non-free mirror

### blackdown-unstable
## Dépôts Blackdown Java, pour installer Java 2 Runtime Environment ; paquets : j2re1.4, j2sdk1.4 (développement)
$nonfree deb ftp://ftp.tux.org/java/debian/ unstable non-free

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FREE - TESTING
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### debian-athlon-testing
## Dépôt Debian pour Athlon X
$testing deb http://mail.linuxvar.it/~gianluca/athlon-xp testing main

### debian-testing
## Dépôts Debian officiels, utiliser avec prudence
$testing deb ftp://ftp.debian.org/debian/ testing main

### nerim-marillat-testing
## Dépôts Nerim / Marillat pour le multimédia, site web, clef publique pour Synaptic
$testing deb ftp://ftp.nerim.net/debian-marillat/ testing main


EOF

__package_cp update