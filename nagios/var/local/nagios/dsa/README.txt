Pour surveiller un nouveau DataPower :
	- creer dans cette arborescence un nouveau ficher : alias_datapower.cfg
	- le contenu du fichier doit ressembler a ceci :

define host{
        use                     dsa-server
        host_name               scadtxi52vadm
        alias                   DSA XI52 VAL/DEV/INF
        address                 scadtxi52vadm.st-cloud.dassault-avion.fr
}

	- redemarrer le process nagios
	- ne pas supprimer les fichiers prefixes datapower_*
Enjoy !!!
