-- profiles table and RLS policies
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table profiles enable row level security;

-- owner can select their row
create policy profiles_select_own on profiles
  for select using (auth.uid() = id);

-- owner can insert their row (client should set id = auth.user.id)
create policy profiles_insert_own on profiles
  for insert with check (auth.uid() = id);

-- owner can update their row
create policy profiles_update_own on profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
