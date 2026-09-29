BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(12);

INSERT INTO auth.users (id, email)
VALUES
  ('11111111-1111-4111-8111-111111111111', 'ordinary-user@example.test'),
  ('22222222-2222-4222-8222-222222222222', 'other-user@example.test'),
  ('33333333-3333-4333-8333-333333333333', 'admin-user@example.test'),
  ('44444444-4444-4444-8444-444444444444', 'target-user@example.test');

INSERT INTO public.profiles (id, full_name, role)
VALUES
  ('11111111-1111-4111-8111-111111111111', 'Ordinary User', 'user'),
  ('22222222-2222-4222-8222-222222222222', 'Other User', 'user'),
  ('33333333-3333-4333-8333-333333333333', 'Admin User', 'admin');

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
SET LOCAL request.jwt.claim.role = 'authenticated';

SELECT is(
  auth.uid(),
  '11111111-1111-4111-8111-111111111111'::uuid,
  'authenticated session resolves the ordinary user identity'
);

SELECT is(
  (
    SELECT full_name
    FROM public.profiles
    WHERE id = '11111111-1111-4111-8111-111111111111'
  ),
  'Ordinary User',
  'authenticated user can read their own profile'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.profiles
    WHERE id = '22222222-2222-4222-8222-222222222222'
  ),
  0::bigint,
  'authenticated user cannot read another user profile'
);

UPDATE public.profiles
SET full_name = 'Updated by Intruder'
WHERE id = '22222222-2222-4222-8222-222222222222';

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.profiles
    WHERE id = '22222222-2222-4222-8222-222222222222'
      AND full_name = 'Updated by Intruder'
  ),
  0::bigint,
  'authenticated user cannot update another user profile'
);

SELECT is(
  (
    SELECT full_name
    FROM public.profiles
    WHERE id = '22222222-2222-4222-8222-222222222222'
  ),
  NULL,
  'the denied update leaves the other user profile hidden from the ordinary user'
);

SELECT throws_ok(
  $$
    INSERT INTO public.profiles (id, full_name)
    VALUES ('44444444-4444-4444-8444-444444444444', 'Pretend Profile')
  $$,
  '42501',
  NULL,
  'authenticated user cannot create a profile for another identity'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.profiles
    WHERE id = '44444444-4444-4444-8444-444444444444'
  ),
  0::bigint,
  'no profile row is created for the other identity'
);

SET LOCAL ROLE anon;

SELECT throws_ok(
  $$
    SELECT *
    FROM public.profiles
  $$,
  '42501',
  NULL,
  'anonymous users cannot read profiles'
);

RESET ROLE;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '33333333-3333-4333-8333-333333333333';
SET LOCAL request.jwt.claim.role = 'authenticated';

SELECT is(
  public.is_admin(),
  true,
  'admin session is recognized by the database helper'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.profiles
  ),
  3::bigint,
  'admin user can read all profiles through the explicit admin-select policy'
);

UPDATE public.profiles
SET full_name = 'Changed by Admin'
WHERE id = '11111111-1111-4111-8111-111111111111';

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.profiles
    WHERE id = '11111111-1111-4111-8111-111111111111'
      AND full_name = 'Changed by Admin'
  ),
  0::bigint,
  'admin cannot update another user profile because the update policy does not exist'
);

SELECT is(
  (
    SELECT full_name
    FROM public.profiles
    WHERE id = '11111111-1111-4111-8111-111111111111'
  ),
  'Ordinary User',
  'admin update denial leaves the customer profile unchanged'
);

SELECT * FROM finish();
ROLLBACK;
