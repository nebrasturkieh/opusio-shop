BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(19);

INSERT INTO auth.users (id, email)
VALUES
  ('10000000-0000-4000-8000-000000000001', 'cart-owner@example.test'),
  ('10000000-0000-4000-8000-000000000002', 'cart-other@example.test');

INSERT INTO public.products (name, slug, image_url, is_active)
VALUES (
  'Cart Test Product',
  'cart-test-product',
  'https://example.test/cart-product.jpg',
  true
);

INSERT INTO public.product_variants (product_id, sku, price_cents, stock_quantity, is_active)
VALUES
  ((SELECT id FROM public.products WHERE slug = 'cart-test-product'), 'cart-variant-1', 1500, 10, true),
  ((SELECT id FROM public.products WHERE slug = 'cart-test-product'), 'cart-variant-2', 1600, 8, true),
  ((SELECT id FROM public.products WHERE slug = 'cart-test-product'), 'cart-variant-3', 1700, 6, true);

INSERT INTO public.cart_items (user_id, variant_id, quantity, product_snapshot)
VALUES
  (
    '10000000-0000-4000-8000-000000000002',
    (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-1'),
    3,
    '{"id":"cart-other-row","name":"Cart Test Product","sku":"cart-variant-1"}'::jsonb
  );

RESET ROLE;

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
SET LOCAL request.jwt.claim.role = 'authenticated';

SELECT is(
  auth.uid(),
  '10000000-0000-4000-8000-000000000001'::uuid,
  'authenticated session resolves the cart owner identity'
);

WITH inserted AS (
  INSERT INTO public.cart_items (
    user_id,
    variant_id,
    quantity,
    product_snapshot
  )
  VALUES (
    '10000000-0000-4000-8000-000000000001',
    (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-2'),
    2,
    '{"id":"cart-owner-row","name":"Cart Test Product","sku":"cart-variant-2"}'::jsonb
  )
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM inserted),
  1::bigint,
  'authenticated owner can create their own cart row'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.cart_items
    WHERE user_id = '10000000-0000-4000-8000-000000000001'
      AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-2')
  ),
  1::bigint,
  'authenticated owner can read their own cart row by variant identity'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.cart_items
    WHERE user_id = '10000000-0000-4000-8000-000000000002'
  ),
  0::bigint,
  'authenticated user cannot read another user cart row'
);

SELECT throws_ok(
  $$
    INSERT INTO public.cart_items (user_id, variant_id, quantity, product_snapshot)
    VALUES (
      '10000000-0000-4000-8000-000000000002',
      (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-3'),
      1,
      '{"id":"cart-other-row-attempt","name":"Cart Test Product","sku":"cart-variant-3"}'::jsonb
    )
  $$,
  '42501',
  NULL,
  'authenticated user cannot insert another user cart row'
);

WITH updated AS (
  UPDATE public.cart_items
  SET quantity = 99
  WHERE user_id = '10000000-0000-4000-8000-000000000002'
    AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-1')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM updated),
  0::bigint,
  'authenticated user cannot update another user cart row'
);

WITH deleted AS (
  DELETE FROM public.cart_items
  WHERE user_id = '10000000-0000-4000-8000-000000000002'
    AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-1')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM deleted),
  0::bigint,
  'authenticated user cannot delete another user cart row'
);

RESET ROLE;

SELECT is(
  (
    SELECT quantity
    FROM public.cart_items
    WHERE user_id = '10000000-0000-4000-8000-000000000002'
      AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-1')
  ),
  3,
  'privileged check confirms the other user cart row remained unchanged'
);

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.cart_items
    WHERE user_id = '10000000-0000-4000-8000-000000000002'
      AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-3')
  ),
  0::bigint,
  'privileged check confirms no foreign cart row was created'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
SET LOCAL request.jwt.claim.role = 'authenticated';

SELECT throws_ok(
  $$
    UPDATE public.cart_items
    SET user_id = '10000000-0000-4000-8000-000000000002'
    WHERE user_id = '10000000-0000-4000-8000-000000000001'
      AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-2')
  $$,
  '42501',
  NULL,
  'owner cannot transfer their own cart row to another user'
);

RESET ROLE;

SELECT is(
  (
    SELECT user_id::text
    FROM public.cart_items
    WHERE variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-2')
  ),
  '10000000-0000-4000-8000-000000000001',
  'privileged check confirms the owner cart row still belongs to the owner after failed transfer'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
SET LOCAL request.jwt.claim.role = 'authenticated';

WITH updated AS (
  UPDATE public.cart_items
  SET quantity = 7
  WHERE user_id = '10000000-0000-4000-8000-000000000001'
    AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-2')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM updated),
  1::bigint,
  'owner can update their own cart row'
);

RESET ROLE;

SELECT is(
  (
    SELECT quantity
    FROM public.cart_items
    WHERE user_id = '10000000-0000-4000-8000-000000000001'
      AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-2')
  ),
  7,
  'privileged check confirms the owner cart row was updated'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
SET LOCAL request.jwt.claim.role = 'authenticated';

WITH deleted AS (
  DELETE FROM public.cart_items
  WHERE user_id = '10000000-0000-4000-8000-000000000001'
    AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-2')
  RETURNING id
)
SELECT is(
  (SELECT count(*)::bigint FROM deleted),
  1::bigint,
  'owner can delete their own cart row'
);

RESET ROLE;

SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.cart_items
    WHERE user_id = '10000000-0000-4000-8000-000000000001'
  ),
  0::bigint,
  'privileged check confirms the owner cart row was deleted'
);

SET LOCAL ROLE anon;
SET LOCAL request.jwt.claim.sub = '';
SET LOCAL request.jwt.claim.role = 'anon';

SELECT throws_ok(
  $$
    SELECT *
    FROM public.cart_items
  $$,
  '42501',
  NULL,
  'anonymous users cannot read cart items'
);

SELECT throws_ok(
  $$
    INSERT INTO public.cart_items (user_id, variant_id, quantity, product_snapshot)
    VALUES (
      '10000000-0000-4000-8000-000000000002',
      (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-3'),
      1,
      '{"id":"cart-anonymous-row","name":"Cart Test Product","sku":"cart-variant-3"}'::jsonb
    )
  $$,
  '42501',
  NULL,
  'anonymous users cannot insert cart items'
);

SELECT throws_ok(
  $$
    UPDATE public.cart_items
    SET quantity = 9
    WHERE user_id = '10000000-0000-4000-8000-000000000002'
      AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-1')
  $$,
  '42501',
  NULL,
  'anonymous users cannot update cart items'
);

SELECT throws_ok(
  $$
    DELETE FROM public.cart_items
    WHERE user_id = '10000000-0000-4000-8000-000000000002'
      AND variant_id = (SELECT id FROM public.product_variants WHERE sku = 'cart-variant-1')
  $$,
  '42501',
  NULL,
  'anonymous users cannot delete cart items'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
