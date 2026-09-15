# System Scheduler / Scripts / Logs

Référence officielle : `system/scheduler.php` de RootMikroManager v3.

Le Scheduler officiel affiche Name, Start Date, Start Time, Interval,
Next Run, Run Count et Comment, avec recherche, Enable/Disable et Remove.
RootMikroManager reproduit ces fonctions.

Les schedulers `Monitor Profile <nom>` sont identifiés comme liés aux profils
Hotspot et leur suppression déclenche un avertissement.

Les `/system script` dont `comment=rootmikromanager` sont des enregistrements du
Selling Report : ils sont protégés contre l'édition, l'exécution et la
suppression depuis l'écran Scripts. Leur suppression reste centralisée dans
Selling Report > Remove Data.

Les vrais scripts RouterOS peuvent être ajoutés, modifiés, exécutés et
supprimés. Les logs disposent d'une recherche et d'un filtre par topic.
