#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__ssh_menu ()
{
  while true; do
    __menu \
    -t 'SSH secure server' \
    -o 'Install SSH' \
    -o 'Configure SSH' \
    -o 'Allow new user' \
    -o 'Connect to remote SSH host' \
    --back --exit

    case $REPLY in
      1) install_ssh;;
      2) config_ssh;;
      3) add_ssh_user;;
      4) remote_ssh_login;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Installation et configuration de SSH
install_ssh ()
{

  # Installation du paquet :
  __package_cp -u install ssh # openssh-client openssh-server

  # Une fois les paquets installés, le client et le serveur seront directement utilisables.
  # Il est possible depuis ce poste de se connecter à un autre serveur SSH
  # ou il est possible de se connecter à ce poste via SSH depuis un autre poste.

  # Cependant, il est préférable pour augmenter la sécurité, de modifier le fichier de configuration :
  config_ssh

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
config_ssh()
{

  # Fichier de configuration du démon sshd :

  # Pour interdire la connexion directe sous root, modifier la ligne suivante :
  echo 'Disable Root Login...'
  sudo sed "s/PermitRootLogin yes/PermitRootLogin no/" ${config_path}ssh/sshd_config

  # Ajouter la ligne suivante pour autoriser uniquement pglinux
  read -p'Add user : ' user
  echo "AllowUsers ${user}" | sudo tee -a ${config_path}ssh/sshd_config

  # Modification du port
  current_ssh_port=$( get_confvar ${config_path}ssh/sshd_config 'Port' )
  ask_var 'ssh_port' "Enter ssh port to use (set: ${current_ssh_port} default: 22) : "
  set_confvar ${config_path}ssh/sshd_config 'Port' "$ssh_port"

  # Utiliser ssh à travers un proxy
  ask_var 'proxy_domain' 'Enter a proxy domaine (or leave blank) : '
  ask_var 'proxy_port' 'Enter a proxy port (or leave blank) : '
  if [ "$proxy_domain" != "" ] && [ "$proxy_port" != "" ]; then
    __package_cp -u install proxy-connect
    sudo echo "ProxyCommand /usr/bin/connect-proxy -4 -S ${proxy_domain}:${proxy_port} %h %p" >> ${config_path}ssh/ssh_config
  fi

  # Vérification du fichier de configuration
  editor ${config_path}ssh/sshd_config

  # Redémarrer le démon pour prendre en compte les modifications :
  ${service_path}ssh restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
command_ssh ()
{

  # Commandes pour se connecter à un serveur distant

  # La commande suivante, permet de se connecter au serveur pgdebian sous l’identité de celui qui lance la commande :
  ssh $domain
  # Il est possible de préciser un autre login avec le paramètre -l :
  ssh -l root $domain
  # Il est possible aussi d’utiliser la syntaxe suivante pour se connecter à pgdebian sous root :
  ssh root@$domain

  #Connexion à un serveur SSH via un autre serveur SSH

  # Si vous avez deux serveurs SSH mais qu’il est nécessaire de se connecter au premier pour pouvoir accéder au deuxième, cette commande permet de réaliser les deux connexions :
  ssh root@serveur1 -t ssh root@serveur2

  # Remarque : Cela est surtout intéressant si la connexion aux serveurs se fait via une clé public (cf chapitre suivant)
  # Connexion SSH en utilisant une clé privée et une clé public

  # Une connexion SSH en utilisant une clé privée et une clé public est plus sécurisée qu’une connexion classique par mot de passe. De plus elle permet d’éviter de ressaisir un mot de passe à chaque connexion.

  # Création de la clé privée et de la clé public :
  # Après la saisie de la pass-phrase (Mot de passe long),
  # cette commande va générer deux fichiers dans le dossier   /.ssh Ÿ :
  # - La clé privée : id_dsa
  # - La clé public : id_dsa.pub
  ssh-keygen -t dsa

  # Ensuite, il faut exporter la clé public sur le ou les serveurs distant à utiliser avec ssh :
  ssh-copy-id -i .ssh/id_dsa.pub root@$domain

  # Après la copie de cette clé, à chaque connexion via ssh, la pass-phrase sera demandée.
  # Pour éviter de saisir la pass-phrase (qui normalement est encore plus longe que le mot de passe),
  # il est possible d’utiliser le démon ssh-agent qui se chargera de mémoriser la pass-phrase pour éviter de la ressaisir :
  # Sous Debian le démon ssh-agent est lancé automatiquement au démarrage de la session.
  # La commande suivante, permet de mémoriser la pass-phrase une fois pour toute pendant la durée de la session :
  ssh-add

  # Une fois cette commande saisie, il est possible de se connecter aux différentes serveurs ssh sans saisir aucun mot de passe ou pass-phrase.
  ssh root@$domain

  # Copier des fichiers entre un serveur et un client ssh avec scp

  # La commande scp livrée avec le paquet ssh, permet de copier des fichiers entre le serveur et le client ssh d’une manière sécurisée.
  # La commande suivante, permet d’envoyer dans le répertoire ${TMPDIR} du serveur pgdebian le fichier ${config_path}fstab disponible sur le serveur local :
  scp ${config_path}fstab root@$domain:$dir

  # Exécuter une commande à distance avec ssh
  # permet de se connecter sous root sur l’ordinateur pgdebian et d’exécuter la commande halt pour arrêter l’ordinateur :
  ssh root@$domain halt

  # Lancer une application graphique disponible sur un serveur distant
  ssh -X $user@$domain

  # Et de lancer l’application graphique en ligne de commande.
  # Le paramètre  -C Ÿ permet de comprimer les données ce qui améliore (un peu) la réactivité :
  ssh -CX $user@$domain

  # Remarque : Une méthode plus efficace pour lancer des applications graphiques est de passer par
  # un serveur FreeNX et un client NoMachine comme expliqué dans ce mémo :
  # - http://www.coagul.org/article.php3 ?id_article=330

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
remote_ssh_login ()
{

  read -p"Enter a list of machines you want to connect to (separeted by spaces) : " MACHINES
  # MACHINES="arche aldebaran lfo"

  # Command to launch for login (ssh, rlogin, telnet...)
  LOGIN_COMMAND=ssh

  # Some variables you don't need to change
  COUNT=1
  NUMBER_OF_MACHINES=`echo $MACHINES | wc -w`

  # Here we go... First we print the hostanmes list
  clear ; echo "Which host do you want to login to ?"
  echo

  for I in $MACHINES ;
  do
    if [ $I = $HOSTNAME ] ; then		# Tests if the machine is
      echo "$COUNT) Login to $I (localhost)"	# the localhost, and if so,
      COUNT=$[ $COUNT + 1 ]			# we indicate it :-)
    else
      echo "$COUNT) Login to $I"
      COUNT=$[ $COUNT + 1 ]
    fi
  done

  echo ; echo -n "Please enter a number between 1 and $[ $COUNT - 1 ] to login, or ENTER to exit: "

  # Now we wait for an answer
  read MACHINE_NUMBER

  # If that answer is empty (--> user pressed ENTER alone), terminate the script
  if [[ ! $MACHINE_NUMBER ]] ;
  then
    exit
  fi

  # Check if the answer is in the correct range
  while [ $MACHINE_NUMBER -lt 1 -o $MACHINE_NUMBER -gt $NUMBER_OF_MACHINES ] ; do
    echo ; echo "Sorry, this is not a valid number."
    echo -n "Please enter a number between 1 and $[ $COUNT - 1 ] (or Ctrl-C to exit): "
    read MACHINE_NUMBER
  done

  # Now we check which hostname the number entered matches to, and log to the
  # matching host
  COUNT=1

  for I in $MACHINES ; do
    if [ $MACHINE_NUMBER = $COUNT ] ; then

      # If the machine is the local host,
      # we start a simple shell instead
      # of a remote login process

      if [ $I = $HOSTNAME ] ;
      then

        echo -n "Login as user [$USER] : " ; read REMOTE_USER

        if [[ ! $REMOTE_USER ]] ;
        then
          sh --login
        else
          su - $REMOTE_USER
        fi

      else				# of a remote login process
        echo -n "Login as user [$USER] : " ; read REMOTE_USER

        if [[ ! $REMOTE_USER ]] ;
        then
          $LOGIN_COMMAND $I
        else
          $LOGIN_COMMAND -l $REMOTE_USER $I
        fi

      fi
    fi

    COUNT=$[ $COUNT + 1 ]

  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# OpenSSH server
# OpenSSH server allows you to securely access your computer from another computer via the SSH protocol.
install_ssh2 ()
{

  # 1. (highly recommended) For security reasons, the first thing you should do is enable the firewall.

  # 2. Install OpenSSH server:
  __package_cp -u install openssh-server

  # 3. (optional) Restrict access to a particular set of users:
  echo "
  Add the following line where $USER_1, $USER_2, ..., $USER_N are the users you want to allow (all other users will be disallowed SSH access) :
  AllowUsers $USER_1 $USER_2 ... $USER_N
  "
  sudo editor ${config_path}ssh/sshd_config

  # 4. Restart the SSH server if you made any of the optional configuration changes above:
  ${service_path}ssh restart

  # 5. If you have enabled the firewall (as was recommended), open the SSH port (port 22 by default) to those IP addresses that you want to allow SSH access. For example, if you want to restrict SSH access to your private network, set the policy to open your SSH port for only 192.168.0.0/16 (i.e., IPs of the form 192.168.xxx.xxx).
  sudo ufw allow from 192.168.0.0/16 to any app OpenSSH

  # 6. If you are behind a router on a private network, give your server a static private IP (e.g., 192.168.1.30) by clicking on the System > Administration > Network menu item and setting up a static IP. Note that the gateway address should be the router's LAN address (e.g., 192.168.0.1 for D-Link and Netgear routers, 192.168.1.1 for Linksys routers, 192.168.2.1 for Belkin and SMC routers, and 192.168.123.254 for US Robotics routers).

  # 7. If you want to access your server over the Internet and are behind a router, configure the router to allow access to your server's SSH port.

  # 8. If you want to access your server over the Internet and your Internet Service Provider doesn't give you a static IP address, you need to set up a publicly accessible hostname.

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SSH tunneling
ssh_tunneling()
{
  # 1. Tunnel to an SSH server through a bastion host using local port forwarding:
  #    where
  #        * $SERVER is the hostname or IP address of the SSH server
  #        * $BASTION is the hostname of IP address of the basion host
  #        * $LOCAL_PORT is the local port through which you want to tunnel (e.g., 2001)
  ssh -fN -L $LOCAL_PORT:$SERVER:22 $BASTION
  ssh localhost:$LOCAL_PORT

  # 2. (optional) If you tunnel often, you might want to edit your ~/.ssh/config file to create profiles for these SSH sessions. See this ~/.ssh/config file as an example.

  # 3. (optional) Set up public key authentication.

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # SSH public key authentication

  # Quick explanation: Public key authentication works as follows. First you create a public key and a private key. Think of the public key as being a lock which only opens with the private key. The private key should reside only on your local machine and is stored in encrypted form using a passphrase that you choose when you first create the key. Never send your private key to anyone. The public key is copied to the various systems that you want to access. Once the public key is installed on another system, you can access that system using your private key as authentication. This authentication is done automatically and there is no need for a password entry. You do however need to enter your passphrase in order to decrypt the private key on your local machine in the first place, but you can do this just once per session on your local machine (e.g., when you first log in to your local machine). This will store the decrypted private key in memory until you log out or until you manually tell the local machine to forget the decrypted private key.

  # 1. Create a private/public key pair on your client:
  ssh-keygen -f ~/.ssh/$KEYFILE

  #    I highly recommend using a non-empty passphrase; you can later set up key management so that you only enter your passphrase once per session. You will now have two files in your ~/.ssh folder:
  #       1. $KEYFILE which contains the private key. Never show or send this file to anyone. Think of this as your secret key.
  #       2. $KEYFILE.pub which contains the public key. Think of this as a lock that only opens with your secret key. You can send this lock to others so that they can install it in their systems so that you can enter their system with your key.

  # 2. Append the contents of your $KEYFILE.pub to the server's ~/.ssh/authorized_keys2 file. If you don't have access, email the server's admin.

  # 3. SSH to server:
  ssh -i $KEYFILE $SERVER
  # Alternatively, you can add the following line to the appropriate host entry in your ~/.ssh/config file:
  # IdentityFile ~/.ssh/$KEYFILE

  #and then ssh to that host as usual without having to use the -i $KEYFILE command line option.
  #4. (optional) If you use SSH tunneling and public key authentication with multiple SSH servers, then you will probably run into a "HOST IDENTIFICATION HAS CHANGED" warning. This is because multiple servers are associated with a single hostname (namely, localhost) through the use of port forwarding. You can resolve this issue as follows (assuming port forwarding for the different target servers are on ports 2001, 2002, ...):

  cp ~/.ssh/known_hosts ~/.ssh/known_hosts.backup
  ssh -fN $BASTION
  ssh-keyscan -H -t rsa,dsa -p 2001 localhost >> ~/.ssh/known_hosts
  ssh-keyscan -H -t rsa,dsa -p 2002 localhost >> ~/.ssh/known_hosts
  ssh-keyscan -H -t rsa,dsa -p ...  localhost >> ~/.ssh/known_hosts

  #where
  #* $BASTION is the hostname of IP address of the basion host
  #5. (optional) Set up SSH key management so that you only have to enter your passphrase once per session.

  #SSH key management (Last changed on 2009-01-10)

  #The following allows you to set things up so that you only have to enter your SSH key passphrase once per login session.

  #1. Load your keys for the remainder of the session (i.e., until you log out):

  ssh-add

  #(You will be prompted for your passphrase.)
  #2. Deactivate your keys:

  ssh-add -D

  #Reverse SSH Tunneling (Last changed on 2009-01-10)

  #Suppose you can't directly SSH from a client to a server (for example, if the server is behind a router for which SSH port forwarding is not set up). Nevertheless, if both the client and the server can SSH to a middle host, then we can set up a reverse tunnel via middle host through which the client can connect to the server.

  #1. On the destination server:

  ssh -R $MIDDLE_LOCAL_PORT:localhost:$SERVER_SSH_PORT $MIDDLE_HOST

  #where
  #* $SERVER_SSH_PORT is the SSH port on the destination server. The default port is 22, unless you specifically changed it.
  #* $MIDDLE_HOST is the host that both the client and the destination server can SSH to.
  #* $MIDDLE_LOCAL_PORT is any free port above 1023 on the middle host (e.g., 4000).
  #2. On the client:

  ssh -fN -L $CLIENT_LOCAL_PORT:localhost:$MIDDLE_LOCAL_PORT $MIDDLE_HOST
  ssh -p $CLIENT_LOCAL_PORT localhost

  #where
  #* $MIDDLE_HOST is the host that both the client and the destination server can SSH to.
  #* $MIDDLE_LOCAL_PORT is any free port above 1023 on the middle host (e.g., 4000).
  #* $CLIENT_LOCAL_PORT is any free port above 1023 on the client (e.g., 4000).

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_short_description='SSH management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"
