# Expiration tickets & nettoyage cookies Hotspot

Règle : ticket expiré => supprimer toutes les entrées /ip/hotspot/cookie du même user, déconnecter /ip/hotspot/active, puis supprimer/appliquer l'expiration du ticket. Le script RouterOS généré par les profils d'expiration réalise aussi ce nettoyage pour fonctionner même application fermée.
