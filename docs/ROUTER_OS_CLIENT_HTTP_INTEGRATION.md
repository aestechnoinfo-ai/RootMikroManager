# RootMikroManager - router_os_client + http

## Packages ajoutés

```yaml
router_os_client: ^2.0.1
http: ^1.6.0
```

## Pourquoi router_os_client

Le package `router_os_client` communique directement avec RouterOS via
socket et fournit déjà :

- TCP standard ;
- SSL/TLS ;
- `talk()` ;
- commandes taggées ;
- plusieurs commandes simultanées ;
- annulation par tag ;
- streaming de commandes longues ;
- exceptions RouterOS spécialisées.

RootMikroManager conserve cependant son client interne car l'application
gère déjà de nombreux modules et doit continuer à supporter les ports API
personnalisés.

### Stratégie

`PackageRouterOsClient` est utilisé comme transport complémentaire pour :
- monitoring continu ;
- Torch ;
- `/interface/listen` ;
- futures opérations concurrentes ;
- commandes qui bénéficient d'un tag/cancel explicite.

Le client interne reste prioritaire pour le CRUD existant et les ports
personnalisés.

## Pourquoi package:http

`http` ne parle pas le protocole RouterOS API 8728/8729.

Il sert à RouterOS REST, disponible sous :

- `https://ROUTER/rest/...` avec `www-ssl` ;
- `http://ROUTER/rest/...` avec `www` à partir de RouterOS v7.9.

RootMikroManager privilégie HTTPS.

`RouterOsRestClient` implémente :

- GET -> RouterOS `print` ;
- PUT -> `add` ;
- PATCH -> `set` ;
- DELETE -> `remove` ;
- POST -> commandes console universelles ;
- Basic Auth ;
- JSON ;
- option certificat auto-signé.

## Règle de sécurité

HTTP simple n'est pas activé par défaut car Basic Auth transporte les
identifiants d'une manière qui nécessite TLS pour éviter leur interception.

## Architecture hybride

RootMikroManager possède désormais trois voies :

1. **Socket interne**
   - intégration existante ;
   - ports personnalisés ;
   - CRUD principal.

2. **router_os_client**
   - ports standards 8728/8729 ;
   - tags ;
   - concurrence ;
   - streaming ;
   - cancellation.

3. **http / REST HTTPS**
   - RouterOS v7 ;
   - endpoints `/rest`;
   - intégrations Web et opérations REST.

Cela évite de confondre protocole API RouterOS et HTTP.
