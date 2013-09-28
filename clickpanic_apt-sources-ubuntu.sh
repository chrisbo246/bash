#!/bin/bash

. global.sh

release=$( lsb_release -cs )

nonfree='#'   # Non-free softwares
source='#'    # Sources codes for developers
unstable='#'  #
proposed='#'  # Pre-version softwares
testing='#'   # Betas
backports='#' # Non offical softwares

cat > ${config_path}apt/sources.list <<EOF

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FREE - STABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### main
## Dépôts principaux
deb http://fr.archive.ubuntu.com/ubuntu ${release} main restricted universe multiverse
# deb http://archive.ubuntu.com/ubuntu/ ${release} main restricted universe multiverse
${source} deb-src http://fr.archive.ubuntu.com/ubuntu ${release} main restricted universe multiverse

### security
## Mises à jours de sécutité importantes
deb http://fr.archive.ubuntu.com/ubuntu ${release}-security main restricted universe multiverse
# deb http://security.ubuntu.com/ubuntu/ $release-security main restricted universe
${source} deb-src http://fr.archive.ubuntu.com/ubuntu ${release}-security main restricted universe multiverse

### updates
## Mises à jours de sécutité complémentaires
deb http://fr.archive.ubuntu.com/ubuntu ${release}-updates main restricted universe multiverse
# deb http://archive.ubuntu.com/ubuntu/ ${release}-updates main restricted universe multiverse
${source} deb-src http://fr.archive.ubuntu.com/ubuntu ${release}-updates main restricted universe multiverse

### canonical
## Dépôts commerciaux
deb http://archive.canonical.com/ubuntu ${release} partner
${source} deb-src http://archive.canonical.com/ubuntu ${release} partner

### ta-spring
## Dépôts TA Spring
deb http://ppa.launchpad.net/spring/ubuntu ${release} main
${source} deb-src http://ppa.launchpad.net/spring/ubuntu ${release} main

### Debian
## Dépôts Debian officiels, utiliser avec prudence
#deb ftp://ftp.debian.org/debian/ stable main


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NON-FREE - STABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# medibuntu
deb http://fr.packages.medibuntu.org/ ${release} free non-free
${nonfree}${source} deb-src http://fr.packages.medibuntu.org/ ${release} free non-free

### plf
## Il s’agit de dépôt légaux en France, mais litigieux dans certains pays (dont les Etats-unis), et qui ne sont donc pas intégrés dans les autres paquets pour ces raisons.
${nonfree} deb http://ppa.launchpad.net/tualatrix/ubuntu ${release} main
${nonfree}${source} deb-src http://ppa.launchpad.net/tualatrix/ubuntu ${release} main

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FREE - PROPOSED
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### ubuntu-proposed
## Mises à jour en prés version
deb http://fr.archive.ubuntu.com/ubuntu ${release}-proposed main restricted universe multiverse
${proposed}${source} deb-src http://fr.archive.ubuntu.com/ubuntu ${release}-proposed main restricted universe multiverse

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FREE - BACKPORTS
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### ubuntu-backports
## Dépôts non pris en charge
deb http://fr.archive.ubuntu.com/ubuntu ${release}-backports main restricted universe multiverse
${backports}${source} deb-src http://fr.archive.ubuntu.com/ubuntu ${release}-backports main restricted universe multiverse

### mirrormax-backports
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
${backports} deb http://ubuntu-backports.mirrormax.net/ ${release}-backports main universe multiverse restricted

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FREE - EXTRAS
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### mirrormax-extras
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
${extras} deb http://ubuntu-backports.mirrormax.net/ ${release}-extras main universe multiverse restricted

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

EOF

__package_cp update