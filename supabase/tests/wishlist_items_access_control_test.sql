BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(19);

INSERT INTO auth.users (id, email)
VALUES
  ('10000000-0000-4000-8000-000000000011', 'wishlist-owner@example.test'),
  ('10000000-0000-4000-8000-000000000012', 'wishlist-other@example.test');

INSERT INTO public.products (name, slug, image_url, is_active)
VALUES
  ('Wishlist Product 1', 'wishlist-product-1', 'https://example.test/wishlist-1.jpg', true),
  ('Wishlist Product 2', 'wishlist-product-2', 'https://example.test/wishlist-2.jpg', true),
  ('Wishlist Product 3', 'wishlist-product-3', 'https://example.test/wishlist-3.jpg', true);

INSERT INTO public.wishlist_items (user_id, product_id, product_snapshot)
VALUES
  (
    '10000000-0000-4000-8000-000000000012',
    (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-1'),
    '{"id":"wishlist-product-1","name":"Wishlist Product 1"}'::jsonb
  );

RESET ROLE;

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000011';
SET LOCAL request.jwt.claim.role = 'authenticated';

SELECT is(
  auth.uid(),
  '10000000-0000-4000-8000-000000000011'::uuid,
  'authenticated session resolves the wishlist owner identity'
);

WITH inserted AS (
  INSERT INTO public.wishlist_items (
    user_id,
    product_id,
    product_snapshot
  )
  VALUES (
    '10000000-0000-4000-8000-000000000011',
    (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2'),
    format('{"id":"%s","name":"Wishlist Product 2"}', (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2'))::jsonb
  )
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM inserted),
  1::bigint,
  'authenticated owner can create their own wishlist row'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.wishlist_items
    WHERE user_id = '10000000-0000-4000-8000-000000000011'
      AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2')
  ),
  1::bigint,
  'authenticated owner can read their own wishlist row by product identity'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.wishlist_items
    WHERE user_id = '10000000-0000-4000-8000-000000000012'
  ),
  0::bigint,
  'authenticated user cannot read another user wishlist row'
);

SELECT throws_ok(
  $$
    INSERT INTO public.wishlist_items (user_id, product_id, product_snapshot)
    VALUES (
      '10000000-0000-4000-8000-000000000012',
      (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-3'),
      '{"id":"wishlist-product-3","name":"Other Wishlist Item"}'::jsonb
    )
  $$,
  '42501',
  NULL,
  'authenticated user cannot insert another user wishlist row'
);

WITH updated AS (
  UPDATE public.wishlist_items
  SET product_snapshot = '{"id":"wishlist-product-1","name":"Changed by Other"}'::jsonb
  WHERE user_id = '10000000-0000-4000-8000-000000000012'
    AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-1')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM updated),
  0::bigint,
  'authenticated user cannot update another user wishlist row'
);

WITH deleted AS (
  DELETE FROM public.wishlist_items
  WHERE user_id = '10000000-0000-4000-8000-000000000012'
    AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-1')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM deleted),
  0::bigint,
  'authenticated user cannot delete another user wishlist row'
);

RESET ROLE;

SELECT is(
  (
    SELECT product_snapshot->>'name'
    FROM public.wishlist_items
    WHERE user_id = '10000000-0000-4000-8000-000000000012'
      AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-1')
  ),
  'Wishlist Product 1',
  'privileged check confirms the other user wishlist row remained unchanged'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.wishlist_items
    WHERE user_id = '10000000-0000-4000-8000-000000000012'
      AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-3')
  ),
  0::bigint,
  'privileged check confirms no foreign wishlist row was created'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000011';
SET LOCAL request.jwt.claim.role = 'authenticated';

SELECT throws_ok(
  $$
    UPDATE public.wishlist_items
    SET user_id = '10000000-0000-4000-8000-000000000012'
    WHERE user_id = '10000000-0000-4000-8000-000000000011'
      AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2')
  $$,
  '42501',
  NULL,
  'owner cannot transfer their own wishlist row to another user'
);

RESET ROLE;

SELECT is(
  (
    SELECT user_id::text
    FROM public.wishlist_items
    WHERE product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2')
  ),
  '10000000-0000-4000-8000-000000000011',
  'privileged check confirms the owner wishlist row still belongs to the owner after failed transfer'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000011';
SET LOCAL request.jwt.claim.role = 'authenticated';

WITH updated AS (
  UPDATE public.wishlist_items
  SET product_snapshot = '{"id":"wishlist-product-2","name":"Wishlist Product 2 Updated"}'::jsonb
  WHERE user_id = '10000000-0000-4000-8000-000000000011'
    AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM updated),
  1::bigint,
  'owner can update their own wishlist row'
);

RESET ROLE;

SELECT is(
  (
    SELECT product_snapshot->>'name'
    FROM public.wishlist_items
    WHERE user_id = '10000000-0000-4000-8000-000000000011'
      AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2')
  ),
  'Wishlist Product 2 Updated',
  'privileged check confirms the owner wishlist row was updated'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000011';
SET LOCAL request.jwt.claim.role = 'authenticated';

WITH deleted AS (
  DELETE FROM public.wishlist_items
  WHERE user_id = '10000000-0000-4000-8000-000000000011'
    AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-2')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM deleted),
  1::bigint,
  'owner can delete their own wishlist row'
);

RESET ROLE;

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.wishlist_items
    WHERE user_id = '10000000-0000-4000-8000-000000000011'
  ),
  0::bigint,
  'privileged check confirms the owner wishlist row was deleted'
);

SET LOCAL ROLE anon;
SET LOCAL request.jwt.claim.sub = '';
SET LOCAL request.jwt.claim.role = 'anon';

SELECT throws_ok(
  $$
    SELECT *
    FROM public.wishlist_items
  $$,
  '42501',
  NULL,
  'anonymous users cannot read wishlist items'
);

SELECT throws_ok(
  $$
    INSERT INTO public.wishlist_items (user_id, product_id, product_snapshot)
    VALUES (
      '10000000-0000-4000-8000-000000000012',
      (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-3'),
      '{"id":"wishlist-product-3","name":"Anonymous Wishlist Item"}'::jsonb
    )
  $$,
  '42501',
  NULL,
  'anonymous users cannot insert wishlist items'
);

SELECT throws_ok(
  $$
    UPDATE public.wishlist_items
    SET product_snapshot = '{"id":"wishlist-product-1","name":"Updated by Anonymous"}'::jsonb
    WHERE user_id = '10000000-0000-4000-8000-000000000012'
      AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-1')
  $$,
  '42501',
  NULL,
  'anonymous users cannot update wishlist items'
);

SELECT throws_ok(
  $$
    DELETE FROM public.wishlist_items
    WHERE user_id = '10000000-0000-4000-8000-000000000012'
      AND product_id = (SELECT id::text FROM public.products WHERE slug = 'wishlist-product-1')
  $$,
  '42501',
  NULL,
  'anonymous users cannot delete wishlist items'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
