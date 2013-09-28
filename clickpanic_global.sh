#!/bin/bash
. system.sh
. divers.sh

# Set OS DIST DistroBasedOn PSUEDONAME REV KERNEL MACH
detect_system

# Check if you are in graphical (X)or CLI environment
# ps -C X
if [ ! -s $DISPLAY ]; then
  echo "X";
else
  echo 'CLI';
fi

# Select display mode
if command -v 'zenity' &>/dev/null ; then
  # . "${file_prefix}zenity_helpers.sh"
  . "${file_prefix}bash_helpers.sh"
  elif command -v 'bash' &>/dev/null ; then
  . "${file_prefix}bash_helpers.sh"
else
  "Shell not suported... exit"
  exit
fi

function isdir()
{
  if [ -d "$1" ]; then
    return 1
  else
    return 0
  fi
}

base_dir="/"
# Primary hierarchy root and root directory of the entire file system hierarchy.
bin_dir="/bin/"
#	Essential command binaries that need to be available in single user mode; for all users, e.g., cat, ls, cp.
boot_dir="/boot/"
#	Boot loader files, e.g., kernels, initrd; often a separate partition[22]
dev_dir="/dev/"
#	Essential devices, e.g., /dev/null.
etc_dir="${config_path}"
#	Host-specific system-wide configuration files
#There has been controversy over the meaning of the name itself. In early versions of the UNIX Implementation Document from Bell labs, /etc is referred to as the etcetera directory,[23] as this directory historically held everything that did not belong elsewhere (however, the FHS restricts /etc to static configuration files and may not contain binaries).[24] Since the publication of early documentation, the directory name has been re-designated in various ways. Recent interpretations include Backronyms such as "Editable Text Configuration" or "Extended Tool Chest".[25]
opt_dir="${config_path}opt/"
# X Window System, Version 11, Release 6.
sgml_dir="${config_path}sgml/"
# Configuration files for SGML.
xml_dir="${config_path}xml/"
# Configuration files for XML.
home_dir="/home/"
#	Users' home directories, containing saved files, personal settings, etc.; often a separate partition.
lib_dir="/lib/"
#	Libraries essential for the binaries in /bin/ and /sbin/.
media_dir="/media/"
#	Mount points for removable media such as CD-ROMs (appeared in FHS-2.3).
mnt_dir="/mnt/"
#	Temporarily mounted filesystems.
opt_dir="/opt/"
#	Optional application software packages.[26]
proc_dir="/proc/"
#	Virtual filesystem documenting kernel and process status as text files, e.g., uptime, network. In Linux, corresponds to a Procfs mount.
root_dir="/root/"
#	Home directory for the root user.
sbin_dir="/sbin/"
#	Essential system binaries, e.g., init, ip, mount.
srv_dir="/srv/"
#	Site-specific data which is served by the system.
tmp_dir="${TMPDIR}/"
#	Temporary files (see also /var${TMPDIR}). Often not preserved between system reboots.
preservedtmp_dir="/var${TMPDIR}/"
# Temporary files to be preserved between reboots.
usr_dir="/usr/"
#	Secondary hierarchy for read-only user data; contains the majority of (multi-)user utilities and applications.[27]
usrbin_dir="/usr/bin/"
# Non-essential command binaries (not needed in single user mode); for all users.
usrinclude_dir="/usr/include/"
# Standard include files.
usrlib_dir="/usr/lib/"
# Libraries for the binaries in /usr/bin/ and /usr/sbin/.
usrsbin_dir="/usr/sbin/"
# Non-essential system binaries, e.g., daemons for various network-services.
usrshare_dir="/usr/share/"
# Architecture-independent (shared) data.
usrsrc_dir="/usr/src/"
# Source code, e.g., the kernel source code with its header files.
usrlocal_dir="/usr/local/"
# Tertiary hierarchy for local data, specific to this host. Typically has further subdirectories, e.g., bin/, lib/, share/.[28]
var_dir="/var/"
#	Variable files—files whose content is expected to continually change during normal operation of the system—such as logs, spool files, and temporary e-mail files. Sometimes a separate partition.
varcache_dir="/var/cache/"
# Application cache data. Such data is locally generated as a result of time-consuming I/O or calculation. The application must be able to regenerate or restore the data. The cached files can be deleted without data loss
varlib_dir="/var/lib/"
# State information. Persistent data modified by programs as they run, e.g., databases, packaging system metadata, etc.
varlock_dir="/var/lock/"
# Lock files. Files keeping track of resources currently in use.
varlog_dir="/var/log/"
# Log files. Various logs.
run_dir="/var/run/"
# Information about the running system since last boot, e.g., currently logged-in users and running daemons.
spool_dir="/var/spool/"
# Spool for tasks waiting to be processed, e.g., print queues and unread mail.

# Services directory
if command -v 'service' &>/dev/null ; then
  service_dir="service "
else
  service_dir=${service_path}"
fi

# Emails directory
if [ $(isdir /var/spool/mail/) -eq 1 ]; then
  mail_dir="/var/spool/mail/"
  # Deprecated location for users' mailboxes.
else
  mail_dir="/var/mail/"
  # Users' mailboxes.
fi

# X11 directory
if [ $(isdir /usr/X11R6/) -eq 1 ]; then
  # Configuration files for the X Window System, version 11.
  usrx11_dir="/usr/X11R6/"
else
  #Configuration files for /opt/.
  x11_dir="${config_path}X11/"
fi

# Apache configuration directory
if [ $(isdir ${config_path}httpd/) -eq 1 ]; then
  apache_conf_dir="${config_path}httpd"
  elif [ $(isdir ${config_path}apache/) -eq 1 ]; then
  apache_conf_dir="${config_path}apache/"
else
  apache_conf_dir="${config_path}apache2/"
}

# Apache log directory
if [ $(isdir /var/log/httpd/) -eq 1 ]; then
  apache_conf_dir="/var/log/httpd"
  elif [ $(isdir /var/log/apache/) -eq 1 ]; then
  apache_conf_dir="/var/log/apache/"
else
  apache_conf_dir="/var/log/apache2/"
}

# Standard web directory
web_dir="/var/www/"

# Current user home directory (see also $PWD)
user_dir="~/"
# Current directory
current_dir="./"

# Command printenv display defined variables

# Run function called by param $1
if [ $# -se 1 ]; then
  echo `$1 $2 $3 $4 $5 $6 $7 $8 $9`
fi