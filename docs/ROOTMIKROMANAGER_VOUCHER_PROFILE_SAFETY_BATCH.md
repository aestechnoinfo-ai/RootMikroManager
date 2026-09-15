# Vouchers & Hotspot profiles — consolidation

- Profiles and tickets are displayed and handled as two different RouterOS objects.
- Profiles: `/ip/hotspot/user/profile`.
- Tickets/vouchers: `/ip/hotspot/user`.
- Generator validates quantity, prefix/suffix, duration and data limit.
- Usernames are refreshed before a batch to reduce duplicate collisions.
- Profile usage and duplicate audits are available.
- Batch cleanup is scoped to an exact comment and unused tickets only.
- Safety summary detects missing profiles, orphan cookies and orphan active sessions.
- Existing expiry cleanup continues to remove cookies and active sessions before removing expired tickets.
