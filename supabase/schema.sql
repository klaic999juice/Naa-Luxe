-- Naa Luxe database schema for Supabase (PostgreSQL)
create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade, email text not null, full_name text, phone text, avatar_url text, role text not null default 'customer' check (role in ('admin','customer')), created_at timestamptz not null default now());
-- A transaction-scoped advisory lock makes first-account admin assignment atomic across concurrent signups.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare assigned_role text;
begin
 perform pg_advisory_xact_lock(78123014);
 if not exists (select 1 from public.profiles) then assigned_role := 'admin'; else assigned_role := 'customer'; end if;
 insert into public.profiles(id,email,full_name,role) values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name',''),'customer');
 if assigned_role='admin' then update public.profiles set role='admin' where id=new.id; end if;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
-- Block role changes by normal authenticated users, including self-promotion.
create or replace function public.protect_profile_role() returns trigger language plpgsql as $$ begin if new.role is distinct from old.role and current_user <> 'postgres' and current_user <> 'service_role' then raise exception 'Profile roles cannot be changed by customers'; end if; return new; end; $$;
drop trigger if exists protect_profile_role_trigger on public.profiles;
create trigger protect_profile_role_trigger before update on public.profiles for each row execute procedure public.protect_profile_role();
create table if not exists public.products(id uuid primary key default gen_random_uuid(),name text not null,slug text not null unique,description text not null default '',price numeric(12,2) not null check(price>=0),discount_price numeric(12,2) check(discount_price>=0),category text, image_url text, stock integer not null default 0 check(stock>=0),is_published boolean not null default false,is_featured boolean not null default false,is_best_seller boolean not null default false,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.orders(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id),reference text not null unique,total numeric(12,2) not null check(total>=0),status text not null default 'pending' check(status in ('pending','processing','shipped','delivered','cancelled')),payment_status text not null default 'pending' check(payment_status in ('pending','paid','failed','refunded')),payment_reference text,delivery jsonb not null,created_at timestamptz not null default now());
create table if not exists public.order_items(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id) on delete cascade,product_id uuid references public.products(id) on delete set null,product_name text not null,quantity integer not null check(quantity>0),unit_price numeric(12,2) not null check(unit_price>=0));
create table if not exists public.payments(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id) on delete cascade,provider text not null,reference text not null unique,amount numeric(12,2) not null,currency text not null default 'GHS',status text not null,gateway_response jsonb,created_at timestamptz not null default now());
create table if not exists public.wishlist_items(user_id uuid not null references public.profiles(id) on delete cascade,product_id uuid not null references public.products(id) on delete cascade,created_at timestamptz not null default now(),primary key(user_id,product_id));
create table if not exists public.community_posts(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,body text not null default '',image_url text,is_announcement boolean not null default false,is_pinned boolean not null default false,created_at timestamptz not null default now(),check(length(body)<=2000));
create table if not exists public.community_comments(id uuid primary key default gen_random_uuid(),post_id uuid not null references public.community_posts(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,parent_id uuid references public.community_comments(id) on delete cascade,body text not null check(length(body) between 1 and 2000),created_at timestamptz not null default now());
create table if not exists public.community_likes(post_id uuid not null references public.community_posts(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,created_at timestamptz not null default now(),primary key(post_id,user_id));
create table if not exists public.community_reports(id uuid primary key default gen_random_uuid(),post_id uuid not null references public.community_posts(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,reason text,created_at timestamptz not null default now(),unique(post_id,user_id));
create table if not exists public.newsletter_subscribers(email text primary key,created_at timestamptz not null default now());
create table if not exists public.notifications(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,title text not null,body text not null,read_at timestamptz,created_at timestamptz not null default now());
create index if not exists orders_user_id_idx on public.orders(user_id);create index if not exists orders_created_at_idx on public.orders(created_at desc);create index if not exists products_category_idx on public.products(category);create index if not exists posts_created_at_idx on public.community_posts(created_at desc);
-- Enable row-level security everywhere; clients can only access their own sensitive records.
do $$ declare t text; begin foreach t in array array['profiles','products','orders','order_items','payments','wishlist_items','community_posts','community_comments','community_likes','community_reports','newsletter_subscribers','notifications'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
create policy "Profiles readable to signed in" on public.profiles for select to authenticated using(true);
create policy "Users edit own non-role profile" on public.profiles for update to authenticated using(auth.uid()=id) with check(auth.uid()=id);
create policy "Published products are public" on public.products for select to anon,authenticated using(is_published or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Admins manage products" on public.products for all to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role='admin')) with check(exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Users see own orders" on public.orders for select to authenticated using(user_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Users see own order items" on public.order_items for select to authenticated using(exists(select 1 from public.orders where id=order_id and (user_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='admin'))));
create policy "Users see own payments" on public.payments for select to authenticated using(exists(select 1 from public.orders where id=order_id and user_id=auth.uid()) or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Own wishlist" on public.wishlist_items for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "Community posts readable" on public.community_posts for select to anon,authenticated using(true);
create policy "Create own community posts" on public.community_posts for insert to authenticated with check(user_id=auth.uid() and not is_announcement and not is_pinned);
create policy "Owner or admin manage posts" on public.community_posts for delete to authenticated using(user_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Admin can pin and announce" on public.community_posts for update to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role='admin')) with check(exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Comments public read" on public.community_comments for select to anon,authenticated using(true);
create policy "Create own comments" on public.community_comments for insert to authenticated with check(user_id=auth.uid());
create policy "Delete own comments or admin" on public.community_comments for delete to authenticated using(user_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Likes public read" on public.community_likes for select to anon,authenticated using(true);
create policy "Like as self" on public.community_likes for insert to authenticated with check(user_id=auth.uid());create policy "Remove own like" on public.community_likes for delete to authenticated using(user_id=auth.uid());
create policy "Report as self" on public.community_reports for insert to authenticated with check(user_id=auth.uid());create policy "Admin read reports" on public.community_reports for select to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
create policy "Manage own notifications" on public.notifications for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "Newsletter public signup" on public.newsletter_subscribers for insert to anon,authenticated with check(true);
create policy "Newsletter admin read" on public.newsletter_subscribers for select to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
-- Storage bucket for admin-managed product/community images. Create it from Supabase SQL editor.
insert into storage.buckets(id,name,public) values('naa-luxe-media','naa-luxe-media',true) on conflict(id) do nothing;
create policy "Public product media read" on storage.objects for select using(bucket_id='naa-luxe-media');
create policy "Admins upload store media" on storage.objects for insert to authenticated with check(bucket_id='naa-luxe-media' and exists(select 1 from public.profiles where id=auth.uid() and role='admin'));
