#!/bin/bash

. global.sh

II.I. Touches d'accès

Une touche d'accès est une touche permettant d'effectuer une action au clavier plutôt qu'en utilisant la souris. Une touche d'accès est identifiée avec une lettre soulignée dans les entrées de menu ou de boîtes de dialogue.

Certaines boîtes de dialogue de Zenity permettent l'utilisation de touches d'accès. Pour indiquer la lettre à utiliser comme touche d'accès, placez un underscore (_) avant cette lettre dans le texte de la boîte de dialogue. L'exemple suivant montre comment utiliser la lettre 'C' comme touche d'accès :

"_Choisissez un nom".

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Zenity retourne les codes de sortie suivants :
Code de sortie	Description
0 	L'utilisateur a appuyé sur OK ou sur Fermer.
1 	L'utilisateur a soit appuyé sur le bouton Annuler, soit fermé la boîte de dialogue.
-1 	Une erreur inattendue s'est produite.
5 	The dialog has been closed because the timeout has been reached.
II.III. Options générales

Toutes les boîtes de dialogue Zenity supportent les options générales suivantes :

--title=titre

Spécifier le titre d'une boîte de dialogue.
--window-icon=chemin_icone

Spécifier l'icône affichée dans le cadre de la boîte de dialogue. Quatre icônes prédéfinies sont également disponibles en utilisant l'un des mots-clés suivants : 'info', 'warning', 'question' et 'error'.
--width=largeur

Spécifier la largeur de la boîte de dialogue.
--height=hauteur

Spécifier la hauteur de la boîte de dialogue.
--timeout=timeout

Specifies the timeout in seconds after which the dialog is closed.

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
II.IV. Options d'aide

Zenity fournit les options d'aide suivantes :

--help

Afficher un court texte d'aide.
--help-all

Afficher le texte d'aide complet pour toutes les boîtes de dialogue.
--help-general

Afficher l'aide pour les options générales.
--help-calendar

Afficher l'aide pour les options de la boîte de dialogue de calendrier.
--help-entry

Afficher l'aide pour les options de la boîte de dialogue de saisie.
--help-error

Afficher l'aide pour les options de la boîte de dialogue d'erreur.
--help-info

Afficher l'aide pour les options de la boîte de dialogue d'information.
--help-file-selection

Afficher l'aide pour les options de la boîte de dialogue de sélection de fichier.
--help-list

Afficher l'aide pour les options de la boîte de dialogue de liste.
--help-notification

Afficher l'aide pour les options de l'icône de notification.
--help-progress

Afficher l'aide pour les options de la boîte de dialogue de barre de progression.
--help-question

Afficher l'aide pour les options de la boîte de dialogue de question.
--help-warning

Afficher l'aide pour les options de la boîte de dialogue d'avertissement.
--help-text-info

Afficher l'aide pour les options de la boîte de dialogue de texte d'information.
--help-misc

Afficher l'aide pour les options diverses.
--help-gtk

Afficher l'aide pour les options GTK+.

II.V. Options diverses

Zenity fournit également les options suivantes :

--about

Afficher la boîte de dialogue À propos de Zenity, qui contient des informations sur la version de Zenity, des informations sur la licence, et des informations sur les développeurs.
--version

Afficher le numéro de version de Zenity.

II.VI. Options GTK+

Zenity supporte les options GTK+ standards. Pour plus d'informations à propos des options GTK+, lancez la commande zenity --help-gtk.
Introduction	Boîte de dialogue de calendrier

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Options de la boîte de dialogue de calendrier :

--text=texte

Spécifier le texte affiché dans la boîte de dialogue de calendrier.
--day=jour

Spécifier le jour sélectionné dans la boîte de dialogue de calendrier. jour doit être un nombre compris entre 1 et 31 inclus.
--month=mois

Spécifier le mois sélectionné dans la boîte de dialogue de calendrier. mois doit être un nombre compris entre 1 et 12 inclus.
--year=année

Spécifier l'année sélectionnée dans la boîte de dialogue de calendrier.
--date-format=format

Spécifier sous quel format la boîte de dialogue de calendrier retourne la date sélectionnée. Le format par défaut dépend de votre localisation. format doit être un format que la fonction strftime accepte, par exemple %A %d/%m/%y.

Le script d'exemple suivant montre comment créer une boîte de dialogue de calendrier :

#!/bin/sh


if zenity --calendar \
--title="Choisissez une date" \
--text="Cliquez sur une date pour la sélectionner." \
--day=10 --month=8 --year=2004
then echo $?
else echo "Aucune date sélectionnée"
fi
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Options de la boîte de dialogue de sélection de fichiers :

--filename=nom_du_fichier

Spécifier le fichier ou le dossier sélectionné au premier affichage de la boîte de dialogue de sélection de fichier.
--multiple

Permettre la sélection de plusieurs fichiers.
--directory

Permettre uniquement la sélection de dossiers.
--save

Mettre la boîte de dialogue de sélection de fichier en mode sauvegarde.
--separator=séparateur

Spécifier le texte utilisé comme séparateur pour diviser la liste des noms de fichiers retournée.

Le script d'exemple suivant montre comment créer une boîte de dialogue de sélection de fichier :

#!/bin/sh

FILE=`zenity --file-selection --title="Sélectionnez un fichier"`

case $? in
  0)
    echo "\"$FILE\" est sélectionné.";;
    1)
    echo "Aucun fichier sélectionné.";;
    -1)
    echo "Aucun fichier sélectionné.";;
esac

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--text=texte

Spécifier le texte affiché dans la zone de notification.

Le script d'exemple suivant montre comment créer une icône de notification :

#!/bin/sh

zenity --notification\
--window-icon="info" \
--text="Mise à jour du système nécessaire !"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Options de la boîte de dialogue de liste :

--column=titre

Spécifier le titre de colonne affiché dans la boîte de dialogue de liste. Vous devez utiliser une option --column pour chaque colonne que vous voulez afficher dans la boîte de dialogue.
--checklist

Utiliser des cases à cocher pour la première colonne de la liste.
--radiolist

Utiliser des boutons radio pour la première colonne de la liste.
--editable

Permettre l'édition des éléments affichés.
--separator=séparateur

Spécifier le texte utilisé comme séparateur pour diviser la liste des entrées sélectionnées que la boîte de dialogue retourne.
--print-column=colonne

Spécifier de quelle colonne afficher le contenu après sélection. La colonne par défaut est '1'. 'ALL' peut être utilisé pour afficher le contenu de toutes les colonnes de la liste.

Le script d'exemple suivant montre comment créer une boîte de dialogue de liste :

#!/bin/sh

zenity --list \
--title="Choisissez les bogues à afficher" \
--column="N° de bogue" --column="Gravité" --column="Description" \
992383 Normal "GtkTreeView plante lors de sélections multiples" \
293823 Grave "Le dictionnaire GNOME ne prend pas de proxy en charge" \
393823 Critique "L'édition de menu ne fonctionne pas avec GNOME 2.0"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

VII.I. Boîte de dialogue d'erreur

Utilisez l'option --error pour créer une boîte de dialogue d'erreur.

Le script d'exemple suivant montre comment créer une boîte de dialogue d'erreur :

#!/bin/bash. global.sh

zenity --error \
--text="Impossible de trouver /var/log/syslog."


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#!/bin/bash. global.sh

zenity --info \
--text="Fusion effectuée. 3 fichiers sur 10 mis à jour."

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#!/bin/bash. global.sh

zenity --question \
--text="Voulez-vous vraiment continuer ?"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#!/bin/bash. global.sh

zenity --warning \
--text="Débranchez le câble pour éviter tout choc électrique."

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

L'option --progress crée une boîte de dialogue de barre de progression.

Zenity lit les données à partir de l'entrée standard, ligne par ligne. Si une ligne commence par '#', le texte est mis à jour avec le texte de cette ligne. Si une ligne contient seulement un nombre, le pourcentage est mis à jour avec ce nombre.

Options de la boîte de dialogue de barre de progression :

--text=texte

Spécifier le texte affiché dans la boîte de dialogue de barre de progression.
--percentage=pourcentage

Spécifier le pourcentage initial réglé dans la boîte de dialogue de barre de progression.
--auto-close

Fermer la boîte de dialogue quand la barre de progression atteint 100%.
--pulsate

Utiliser une barre de progression discontinue jusqu'à ce qu'un caractère EOF soit lu sur l'entrée standard.

Le script d'exemple suivant montre comment créer une boîte de dialogue de barre de progression :

#!/bin/sh
(
  echo "10" ; sleep 1
  echo "# Mise à jour des journaux de mail" ; sleep 1
  echo "20" ; sleep 1
  echo "# Remise à zéro des paramètres" ; sleep 1
  echo "50" ; sleep 1
  echo "Cette ligne est ignorée" ; sleep 1
  echo "75" ; sleep 1
  echo "# Redémarrage du système" ; sleep 1
  echo "100" ; sleep 1
) |
zenity --progress \
--title="Mise à jour des journaux système" \
--text="Analyse des journaux de mail..." \
--percentage=0

if [ "$?" = -1 ] ; then
  zenity --error \
  --text="Mise à jour annulée."
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

L'option --entry crée une boîte de dialogue de saisie. Zenity retourne le texte saisi sur le flux d'erreur standard.

Options de la boîte de saisie :

--text=texte

Spécifier le texte affiché dans la boîte de dialogue de saisie.
--entry-text=texte

Spécifier le texte affiché dans le champ de saisie de la boîte de dialogue.
--hide-text

Cacher le texte dans le champ de saisie de la boîte de dialogue.

Le script d'exemple suivant montre comment créer une boîte de dialogue de saisie :

#!/bin/sh

if zenity --entry \
--title="Ajouter une entrée" \
--text="Saisissez votre mot de _passe :" \
--entry-text "password" \
--hide-text
then echo $?
else echo "Aucun mot de passe entré"
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
L'option --text-info crée une boîte de dialogue de texte d'information.

Options de la boîte de dialogue de texte d'information :

--filename=nom_du_fichier

Spécifier un fichier texte à charger dans la boîte de dialogue de texte d'information.
--editable

Permettre l'édition du texte affiché. Le texte édité est retourné sur le flux d'erreur standard à la fermeture de la boîte de dialogue.

Le script d'exemple suivant montre comment créer une boîte de dialogue de texte d'information :

#!/bin/sh

FILE=`zenity --file-selection \
--title="Choisissez un fichier"`

case $? in
  0)
    zenity --text-info \
    --title=$FILE \
    --filename=$FILE \
  --editable 2>${TMPDIR}${TMPDIR}.txt;;
  1)
  echo "Aucun fichier sélectionné.";;
  -1)
  echo "Aucun fichier sélectionné.";;
esac

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~




