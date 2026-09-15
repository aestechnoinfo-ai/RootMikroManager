# DHCP / Status / Traffic - parité RootMikroManager v7.135

Sources analysées :
- `dhcp/dhcpleases.php`
- `status/ping-test.php`
- `status/status.php`
- `traffic/traffic.php`
- `traffic/trafficmonitor.php`

## DHCP Leases
La vue reprend : D/S, Address, MAC Address, Server, Active Address,
Active MAC Address, Active Host Name, Status, recherche et compteur.

## Ping Test
RootMikroManager ne fait pas d'ICMP : `ping-test.php` ouvre une socket TCP sur le
port API configuré, 8728 par défaut. RootMikroManager reproduit cela avec
`Socket.connect(..., timeout: 5s)`. Ce test reste pertinent via ZeroTier,
WireGuard ou BackToHome car il vérifie l'accessibilité TCP réelle.

## Traffic
RootMikroManager utilise `/interface/monitor-traffic` avec `once` et lit
`tx-bits-per-second` / `rx-bits-per-second`. RootMikroManager conserve son
streaming + fallback `once` et corrige le repaint du graphe RX/TX.
