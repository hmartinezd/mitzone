# Production connection lifecycle

The lifecycle is `eligible encounter → pending request → accepted/declined`; only participants can read requests and connections. Production commands are authenticated RPCs and re-check the encounter's current availability and symmetric blocks. Clients cannot insert, update, or delete relationship rows directly.

Requests are idempotent. Repeating A→B returns the same pending request without another notification. If B sends while A→B is pending, the existing request is accepted and one canonical A-B connection is created. The accepted notification is addressed to the original sender. Connections use sorted user IDs, and a blocked pair is hidden and cannot accept, send, or remove through an unauthorized path. Unblocking does not recreate removed or invalidated relationships.

Request and acceptance notifications are created inside secured commands with conflict protection. Notification failure remains a separate concern from the underlying command boundary; push delivery is not part of this sprint.
