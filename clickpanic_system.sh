#!/bin/bash
__get_system_env()
{
  YES=0 # TRUE
  NO=1 # FALSE
  ERR=999 # DEFAULT VALUE OR ERROR CODE
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Displays OS name for example FreeBSD, Linux etc

getOs(){
  echo "$(uname)"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_release()
{
  echo "$(lsb_release -cs)"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Display CPU information such as Make, speed

getCpuInfo()
{
  if [ "$OS" == "FreeBSD" ]; then
    if ( isRootUser ); then # this is more reliable
      echo "$($GREP "CPU" /var/log/dmesg.today | $HEAD -1)"
    else # this may fail
      echo "$($DMESG | $GREP "CPU" | $HEAD -1)"
    fi
    elif [ "$OS" == "Linux" ]; then

    :
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Display message and exit with exit code

die(){
  message="$1"
  exitCode=$2
  echo "$message"
  [ "$2" == "" ]  >&2 && exit 1 || exit $exitCode
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Display avilable RAM in system

getRealRamInfo(){
  if [ "$OS" == "FreeBSD" ]; then
    if ( isRootUser ); then # this is more reliable
      echo "$($GREP -E "^real memory" /var/log/dmesg.today)|$CUT -d'(' -f2 | cut -d')' -f1)"
    else
      echo "$($DMESG | $GREP -E '^real memory' | $CUT -d'(' -f2 | cut -d')' -f1)"
    fi
    elif [ "$OS" == "Linux" ]; then
    :
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Display system load for last 5,10,15 minutes

getSystemLoad(){
  [ "$OS" == "FreeBSD" ] && echo "$($UPTIME | $AWK -F'averages:' '{ print $2 }')" || :
  [ "$OS" == "Linux" ] && echo "$($UPTIME | $AWK -F'load average:' '{ print $2 }')" || :
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Display Dynamically loaded kernel module aka drivers (both linux and FreeBSD)

getNumberOfKernelModules(){
  [ "$OS" == "FreeBSD" ] && echo "$($KLDSTAT | $GREP -vE "^Id Refs" | $WC -l)"
  [ "$OS" == "Linux" ] && echo "$($LSMOD | $GREP -vE "^Module" | $WC -l)"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Display current OS runlevel with Description of it

getOsRunLevel(){
  if [ "$OS" == "FreeBSD" ]; then
    r="$($SYSCTL -a | $GREP -wE "^kern.securelevel" | $AWK '{ print $2}')"
    case "$r" in
      -1) d="Permanently insecure mode";;
      0) d="Insecure mode";;
      1) d="Secure mode";;
      2) d="Highly secure mode";;
      3) d="Network secure mode";;
      *) d="Unknown runlevel";;
    esac
    elif [ "$OS" == "Linux" ]; then
    r="$($RUNLEVEL | $AWK '{ print $2}')"
    case "$r" in
      1) d="Single user mode";;
      2) d="Multi-user without NFS";;
      3) d="Full multi-user";;
      4) d="Unused/Experimental";;
      5) d="Multi-user with X11 windows";;
      *) d="Unknown runlevel";;
    esac
  fi
  echo "$r ($d)"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run graphic environment
envlaunch ()
{

  FILE=${TMPDIR}/envlaunched #Une adresse de fichier temporaire.
  if test -e $FILE
  then exit 0
  fi #Si le fichier temporaire existe, un environnement est en cours d'exécution, on s'arrête là.
  case $* in
    WindowMaker) wmaker;; #Ça, c'est tout simple.
    Gnome) touch $FILE #On crée le fichier de blocage.
      killall wmclock #Cet utilitaire ne sert que sous WindowMaker.
      killall WindowMaker #On va changer de gestionnaire de fenêtres.
      gnome-session #Lancement de la session Gnome.
      killall gnome-power-manager #Ce truc se lance systématiquement quand Gnome se termine, je ne sais pas pourquoi, et j'en veux pas.
      wmclock & #On relance l'utilitaire.
    rm $FILE;; #Suppression du fichier de blocage pour relancer WindowMaker.
    KDE) touch $FILE
      killall wmclock
      killall WindowMaker
      startkde #Lancement de la session KDE
      bash -i -c "sleep 2; guidance-power-manager" & #KDE termine guidance-power-manager en se terminant, donc je le relance.
      wmclock &
    rm $FILE;;
    Xfce) touch $FILE
      killall wmclock
      killall WindowMaker
      startxfce4 #Lancement de la session Xfce
      wmclock &
    rm $FILE;;
    e17) touch $FILE
      killall wmclock
      killall WindowMaker
      enlightenment_start #Lancement d'Enlightenment
      wmclock &
    rm $FILE;;
  esac

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
detect_system()
{

  OS=`lowercase \`uname\``
  KERNEL=`uname -r`
  MACH=`uname -m`

  if [ "{$OS}" == "windowsnt" ]; then
    OS=windows
    elif [ "{$OS}" == "darwin" ]; then
    OS=mac
  else
    OS=`uname`
    if [ "${OS}" = "SunOS" ] ; then
      OS=Solaris
      ARCH=`uname -p`
      OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
      elif [ "${OS}" = "AIX" ] ; then
      OSSTR="${OS} `oslevel` (`oslevel -r`)"
      elif [ "${OS}" = "Linux" ] ; then
      if [ -f ${config_path}redhat-release ] ; then
        DistroBasedOn='RedHat'
        DIST=`cat ${config_path}redhat-release |sed s/\ release.*//`
        PSUEDONAME=`cat ${config_path}redhat-release | sed s/.*\(// | sed s/\)//`
        REV=`cat ${config_path}redhat-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f ${config_path}SuSE-release ] ; then
        DistroBasedOn='SuSe'
        PSUEDONAME=`cat ${config_path}SuSE-release | tr "${IFS}" ' '| sed s/VERSION.*//`
        REV=`cat ${config_path}SuSE-release | tr "${IFS}" ' ' | sed s/.*=\ //`
        elif [ -f ${config_path}mandrake-release ] ; then
        DistroBasedOn='Mandrake'
        PSUEDONAME=`cat ${config_path}mandrake-release | sed s/.*\(// | sed s/\)//`
        REV=`cat ${config_path}mandrake-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f ${config_path}debian_version ] ; then
        DistroBasedOn='Debian'
        DIST=`cat ${config_path}lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
        PSUEDONAME=`cat ${config_path}lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
        REV=`cat ${config_path}lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
      fi
      if [ -f ${config_path}UnitedLinux-release ] ; then
        DIST="${DIST}[`cat ${config_path}UnitedLinux-release | tr "${IFS}" ' ' | sed s/VERSION.*//`]"
      fi
      OS=`lowercase $OS`
      DistroBasedOn=`lowercase $DistroBasedOn`
      readonly OS
      readonly DIST
      readonly DistroBasedOn
      readonly PSUEDONAME
      readonly REV
      readonly KERNEL
      readonly MACH
    fi

  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_short_description='System management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
