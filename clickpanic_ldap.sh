#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__ldap_menu ()
{
  while true; do
    __menu \
    -t 'LDAP' \
    -o 'Install LDAP server' \
    --back --exit

    case $REPLY in
      1) install_ldap_server;;
    esac
  done
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_ldap_config ()
{

  # Le demon ldap poss�de 2 fichiers de configuration :

  # ce fichier comporte diverses informations telles que la racine sup�rieure de l'annuaire, l'administrateur principal de l'annuaire LDAP et son mot de passe, les droits d'acc�s par d�faut, les fichiers d'objets et de syntaxe � utiliser ainsi que les r�gles d'acc�s pour les entr�es et les attributs de l'annuaire LDAP.
  editor ${config_path}ldap/slapd.conf  # qui est le fichier de configuration du d�mon slapd.

  editor ${config_path}ldap/ldap.conf   # qui est le fichier de configuration des utilitaires LDAP.

  #xxx.oc.conf  # Les fichiers d'objets
  #le fichier par d�faut est slapd.oc.conf. Ils contiennent la d�claration de chaque objet de l'annuaire LDAP.
  #xxx.at.conf   #Les fichiers d'attributs

  # le fichier par d�faut est slapd.at.conf. Ces fichiers contiennent la syntaxe de chaque attribut composant les objets.
  # Edition du fichier slapd.oc.conf
  # Le fichier etc/openldap/slapd.oc.conf d�crit la structure des objets qui vont �tre utilis�s dans l'annuaire LDAP.
  # Il est inclu dans le fichier slapd.conf par la directive include ${config_path}openldap/slapd.oc.conf.

  Configuration
  editor ${config_path}ldap/slapd.conf   # Editer le fichier de configuration
  allow bind_v2                     # Autoriser l�utilisation de la norme V2 de LDAP.
  suffix "dc=mondomaine,dc=com"     # Donne la racine de la base LDAP

  # Obligatoires pour avoir un acc�s root sur la base depuis un programme externe (Ex: PHP):
  rootdn "cn=admin,dc=mondomaine ,dc=com"  # donne le login de l�administrateur (admin avec le rappel de la racine).
  rootpw admin                             # donne le mot de passe en clair

  # Param�trage de l�acc�s en �criture de la base. Il faut indiquer le bon login et la racine de la base :
  access to attribute=userPassword
  by dn="cn=admin,dc=test,dc=com" write
  by anonymous auth
  by self write
  by * none

  Param�trage de l�acc�s en lecture seule de la base. Il faut indiquer le bon login et la racine de la base :
  access to *
  by dn="cn=admin,dc=test,dc=com" write
  by * read

  # Ajouter ces quatre lignes apr�s la section "database" (vers les lignes 70).
  suffix          "dc=example,dc=com"
  directory       "/var/lib/ldap"
  rootdn          "cn=admin,dc=example,dc=com"
  rootpw          {SSHA}d2BamRTgBuhC6SxC0vFGWol31ki8iq5m

  Si jamais vous voulez activer le support de la version pr�c�dente d'LDAP, d�commentez l'option (ligne 8) :
  allow bind_v2

  sudo dpkg-reconfigure slapd

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_ldap_server ()
{

  echo "
Voici brievement les r�ponses attendues pour une installation standard

1.Passer la configuration d'OpenLDAP ? non
2.Nom de domaine ? example.com
3.Nom de votre soci�t� ? masoci�t�
4.Quelle base de donn�e ? hdb
5.Voulez-vous que la base de donn�e soit effac�e lorsque slapd est purg� ? oui
6.Supprimer les anciennes bases de donn�es ? oui
7.Mot de passe administrateur ? VotreMotDePasse
8.Confirmer ce mot de passe ? VotreMotDePasse
9.Authoriser le protocol LDAPv2 ? non
  "

  # Installation du daemon du server ldap (slapd) sur le serveur.
  # On vous demandera votre mot de passe administrateur et �ventuellement votre nom de domaine.
  __package_cp -u install slapd ldap-utils
  editor ${config_path}ldap/ldap.conf

  # S�curiser le fichier de configuration comportant le mot de passe admin en claire
  chmod 600 ${config_path}openldap/slapd.conf

  # Donner des regles � une partie de l'arbre
  # Quelques indications pour la gestion des acc�s � votre annuaire.
  # Dans le cas actuel, toutes les personnes ont un acc�s en lecture mais il est possible de donner des droits particuliers en utilisant la directive access dont la syntaxe est :
  # access to <une partie de l'arbre> [by <une personne> <droits none|search|read|write>]

  # De plus, l'ordre d'�criture des r�gles a une grande importance. Par exemple :
  #   access to dn= � .*, o=commentcamarche, c=fr � by * search
  #   access to dn= � .*, c=fr � by * read
  # Signifie que tout le monde a le droit en lecture sur toute l'arborescence c=fr except� sur la partie o=commentcamarche o� les utilisateurs ont un droit en recherche seulement. Le fait d'inverser l'ordre de ces deux lignes, impliquera que la directive concernant c=fr en lecture sera la seule � �tre prise en compte et, on ne prot�gera plus ainsi la partie de l'arbre o=commentcamarche en recherche seulement.

  # Red�marrer le serveur
  ${service_path}slapd restart

  # Le serveur LDAP doit �tre lanc�
  # Lance se service LDAP aux run-levels 3,4,5 � chaque d�marrage du serveur.
  chkconfig --level 345 ldap on
  # Stop le service aux run-levels 0,1,2,6
  chkconfig --level 0126 ldap off

  # V�rifier si l'entr�e fonctionne :
  slapcat

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_ldap_admin ()
{

  # Pr�-requis: Avoir un serveur WEB install�, voir LAMP.
  sudo __package_cp -y install apache2
  sudo __package_cp -y install php5 libapache2-mod-php5 libapache2-mod-auth-mysql
  sudo __package_cp -y install mysql-server mysql-client

  __package_cp -u install php5-ldap phpldapadmin

  public_ip=$(wget http://checkip.dyndns.org/ -O - -o /dev/null  | awk '{ print  $6 }' | cut -d\< -f 1)
  firefox http://$public_ip/phpldapadmin/
  login: "cn=admin,dc=example,dc=com".

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remplir LDAP
edit_ldap_ldif ()
{

  # L'annuaire LDAP peut �tre rempli par des fichiers ldif (ldif signifie ldap directory interchange format).
  ${service_path}slapd stop
  editor init.ldif           # G�n�rez un fichier de donn�es � ajouter � la base (ex :init.ldif)
  ${service_path}slapd restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Remplir LDAP par export
export_ldap ()
{
  # Ou l'exporter depuis le carnet d'adresse d'un logiciel de messagerie par exemple
  ${service_path}slapd stop    # Arretez le daemon
  sudo rm -rf /var/lib/ldap/*    # Supprimer ce qui a �t� ajout� automatiquement � l'installation
  sudo slapadd -l init.ldif      # Ajouter les donn�es
  ${service_path}slapd start   # Relancer ldap
  ${service_path}slapd restart

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
search_ldap ()
{

  read -p"Enter searched name : " search
  ldapsearch -xLLL uid=$search sn givenName cn   # Effectuer une recherche dans les annuaires LDAP
  # -x    # d�sactive l'authentification SASL
  # -LLL  # empeche l'affichage des informations LDIF

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
repaire_sdap ()
{

  # R�parrer une base corompue suite � un plantage du serveur
  ${service_path}slapd stop
  slapindex
  ${service_path}slapd start

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# R�plication des donn�es LDAP
replic_ldap ()
{

  # Se conecter au serveur de r�plication

  # L'exemple suivant montre une replication
  # sur le serveur ldap-2.example.com ex: ldap-2.example.com
  # avec le Manager user et le mot de passe secret.
  # Le fichier de log est l'emplacement o� les donn�es seront stock�es avant d'etre envoy�es sur le(s) serveur(s) esclave(s).
  ask_var 'ldap_replication_domain' 'Enter replication server domaine name : '
  domaine=$ldap_replication_domain
  replica uri=ldap://$domaine:389 binddn="cn=Manager,dc=example,dc=com" bindmethod=simple credentials=secret
  replogfile      /var/lib/ldap/replog

  # Il ne reste plus qu'a red�marrer votre serveur LDAP :) Le(s) Esclave(s)

  echo "
  # Sur le(s) serveur(s) esclave(s) , il vous suffit d'autoriser votre serveur maitre � mettre � jour la base de donn�e LDAP.
  # Pour cela ajoutez les lignes suivantes dans votre ${config_path}ldap/slapd.conf � la section base de donn�es :
  # updatedn        cn=Manager,dc=example,dc=com
  # updateref       ldap://ldap-1.example.com
  "
  editor ${config_path}ldap/slapd.conf

  # Red�marrez votre serveur LDAP (l'esclave).
  ${service_path}slapd restart

  # D�connexion

  # Sur le maitre, vous devez modifier la section "base de donn�e" du fichier de configuration
  # pour ajouter une instruction de r�plication.
  editor ${config_path}ldap/slapd.conf
  ${service_path}slapd restart
  firefox http://localhost/phpldapadmin/

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
change_ldap_pwd ()
{

  read -p"Enter new LDAP password : " pwd

  sudo slappasswd $pwd                   # G�nere un mot de passe administrateur LDAP chiffr�

  # Il faut ensuite le copier � la place du mot de passe en clair dans le fichier de configuration.

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

script_short_description='LDAP management functions';
script_version='0.0.1'
[[ ! $(declare -Ff include_once) ]] && . "${BASH_SOURCE%/*}/clickpanic.sh"