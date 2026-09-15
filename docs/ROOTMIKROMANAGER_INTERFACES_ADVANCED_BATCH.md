# Interfaces avancées

Ce lot ajoute :
- inventaire de toutes les interfaces ;
- détails et édition basique ;
- monitoring RX/TX existant relié au hub ;
- interfaces VLAN ;
- Bridges et ports Bridge ;
- adresses IP.

## VLAN
L'éditeur crée et modifie `/interface/vlan` avec interface parent, VLAN ID,
MTU, service tag, commentaire et état.

## Bridge
La création d'un Bridge force `vlan-filtering=no`. RootMikroManager ne
l'active pas automatiquement : les ports et la table VLAN doivent d'abord être
préparés afin d'éviter de perdre l'accès d'administration au routeur.

## Adresses IP
Ajout et suppression d'entrées statiques `/ip/address`. Les entrées dynamiques
sont affichées en lecture seule.
