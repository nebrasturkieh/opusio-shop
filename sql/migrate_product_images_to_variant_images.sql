-- Migrate images from products.images JSONB array → variant_images table.
--
-- For each product that has a non-empty images array, this inserts one row
-- per image per variant into variant_images (skipping duplicates).
--
-- Idempotent: uses ON CONFLICT DO NOTHING (requires the unique index below).
-- Run once; safe to re-run.

-- 1. Add a unique index so the upsert is idempotent (IF NOT EXISTS is supported on indexes).
CREATE UNIQUE INDEX IF NOT EXISTS variant_images_variant_url_unique
  ON variant_images (variant_id, image_url);

-- 2. Insert images from products.images into variant_images for every variant.
INSERT INTO variant_images (variant_id, image_url, sort_order, role)
SELECT
  pv.id                                         AS variant_id,
  img.value #>> '{}'                            AS image_url,   -- unwrap jsonb text
  (img.ordinality - 1)::integer                 AS sort_order,  -- 0-based
  CASE
    WHEN img.ordinality = 1 THEN 'front'
    ELSE NULL
  END                                           AS role
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
JOIN LATERAL jsonb_array_elements(p.images) WITH ORDINALITY AS img(value, ordinality)
  ON true
WHERE
  p.images IS NOT NULL
  AND jsonb_typeof(p.images) = 'array'
  AND jsonb_array_length(p.images) > 0
  AND pv.is_active = true
  AND (img.value #>> '{}') IS NOT NULL
  AND (img.value #>> '{}') != ''
ON CONFLICT (variant_id, image_url) DO NOTHING;

-- 3. (Optional) Also set product_variants.image_url = first image if it's null.
UPDATE product_variants pv
SET image_url = (
  SELECT p.images ->> 0
  FROM products p
  WHERE p.id = pv.product_id
    AND p.images IS NOT NULL
    AND jsonb_typeof(p.images) = 'array'
    AND jsonb_array_length(p.images) > 0
)
WHERE pv.image_url IS NULL
  AND EXISTS (
    SELECT 1 FROM products p
    WHERE p.id = pv.product_id
      AND p.images IS NOT NULL
      AND jsonb_typeof(p.images) = 'array'
      AND jsonb_array_length(p.images) > 0
  );

-- Preview what was inserted:
SELECT
  p.name          AS product,
  pv.id           AS variant_id,
  vi.sort_order,
  vi.role,
  vi.image_url
FROM variant_images vi
JOIN product_variants pv ON pv.id = vi.variant_id
JOIN products p ON p.id = pv.product_id
ORDER BY p.name, pv.id, vi.sort_order;
