# Production notifications foundation

Notifications are backend-neutral records owned by exactly one authenticated recipient. The supported types are the existing connection request, connection accepted, and new message activity. Records contain only identifiers, type, destination, timestamps, and read state; they do not contain presence evidence, personality traits, or authentication data.

Demo uses the existing local repository. Production uses Supabase, where clients can read and update only their own rows. Inserts are deliberately unavailable to normal clients: future secured social operations are the creation authority. Push delivery is out of scope.

Read state is stored in `read_at`, so unread counts survive restart, sign-in, and multiple devices. Opening a notification must still re-check the destination's current authorization and safety; a stale or blocked resource is handled as unavailable.
