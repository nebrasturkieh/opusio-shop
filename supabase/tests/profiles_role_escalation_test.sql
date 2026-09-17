BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(8);

-- Create only the Auth identity as the privileged test setup.
INSERT INTO auth.users (id, email)
VALUES (
  '10000000-0000-0000-0000-000000000001',
  'ordinary-user@example.test'
);

-- Run all application actions as an ordinary authenticated user.
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub =
  '10000000-0000-0000-0000-000000000001';
SET LOCAL request.jwt.claim.role = 'authenticated';

SELECT is(
  auth.uid(),
  '10000000-0000-0000-0000-000000000001'::uuid,
  'test session resolves the ordinary user identity'
);

SELECT throws_ok(
  $$
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
      '10000000-0000-0000-0000-000000000001',
      'Ordinary User',
      'admin'
    )
  $$,
  '42501',
  NULL,
  'ordinary user cannot create an admin profile'
);

SELECT lives_ok(
  $$
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
      '10000000-0000-0000-0000-000000000001',
      'Ordinary User',
      'user'
    )
  $$,
  'ordinary user can create their own non-admin profile'
);

SELECT is(
  public.is_admin(),
  false,
  'ordinary user is not recognized as an admin'
);

SELECT lives_ok(
  $$
    UPDATE public.profiles
    SET full_name = 'Updated Ordinary User'
    WHERE id = '10000000-0000-0000-0000-000000000001'
  $$,
  'ordinary user can update a non-privileged profile field'
);

SELECT is(
  (
    SELECT full_name
    FROM public.profiles
    WHERE id = '10000000-0000-0000-0000-000000000001'
  ),
  'Updated Ordinary User'::text,
  'ordinary user profile update is persisted inside the test transaction'
);

SELECT throws_ok(
  $$
    UPDATE public.profiles
    SET role = 'admin'
    WHERE id = '10000000-0000-0000-0000-000000000001'
  $$,
  '42501',
  NULL,
  'ordinary user cannot promote themselves to admin'
);

SELECT is(
  (
    SELECT role
    FROM public.profiles
    WHERE id = '10000000-0000-0000-0000-000000000001'
  ),
  'user'::text,
  'failed escalation leaves the ordinary user role unchanged'
);

SELECT * FROM finish();
ROLLBACK;
