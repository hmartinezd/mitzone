alter table public.connection_requests drop constraint if exists connection_requests_sender_user_id_fkey, drop constraint if exists connection_requests_recipient_user_id_fkey;
alter table public.connection_requests add constraint connection_requests_sender_user_id_fkey foreign key (sender_user_id) references auth.users(id) on delete cascade, add constraint connection_requests_recipient_user_id_fkey foreign key (recipient_user_id) references auth.users(id) on delete cascade;
alter table public.connections drop constraint if exists connections_user_a_id_fkey, drop constraint if exists connections_user_b_id_fkey;
alter table public.connections add constraint connections_user_a_id_fkey foreign key (user_a_id) references auth.users(id) on delete cascade, add constraint connections_user_b_id_fkey foreign key (user_b_id) references auth.users(id) on delete cascade;
alter table public.conversations drop constraint if exists conversations_connection_id_fkey;
alter table public.conversations add constraint conversations_connection_id_fkey foreign key (connection_id) references public.connections(id) on delete cascade;
alter table public.messages drop constraint if exists messages_conversation_id_fkey;
alter table public.messages add constraint messages_conversation_id_fkey foreign key (conversation_id) references public.conversations(id) on delete cascade;
