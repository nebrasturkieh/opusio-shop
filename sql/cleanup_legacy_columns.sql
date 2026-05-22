-- Short-term DB cleanup: remove columns that are fully superseded
-- by the variant-based architecture.
--
-- cart_items.product_id  → replaced by variant_id (new unique key)
-- products.currency      → currency lives on orders, not products

-- ── 1. Purge orphaned rows with no variant ─────────────────────────────────
-- Old guest or migrated rows may have variant_id = NULL. Remove them first
-- so the final unique index can be clean and unconditional.
DELETE FROM cart_items
WHERE variant_id IS NULL;

-- ── 2. Consolidate unique indexes on cart_items ────────────────────────────
-- Drop both the old partial index (from add_variant_images migration) and any
-- previously created full index, then create one clean unconditional index.
DROP INDEX IF EXISTS cart_items_user_id_variant_id_key;
DROP INDEX IF EXISTS cart_items_user_variant_unique;

CREATE UNIQUE INDEX cart_items_user_variant_unique
  ON cart_items (user_id, variant_id);

-- ── 3. Drop the old product_id unique constraint and column ───────────────
ALTER TABLE cart_items
  DROP CONSTRAINT IF EXISTS cart_items_user_id_product_id_key;

ALTER TABLE cart_items
  DROP COLUMN IF EXISTS product_id;

-- ── 4. products ────────────────────────────────────────────────────────────
-- currency is stored on orders (orders.currency); never read from products.
ALTER TABLE products
  DROP COLUMN IF EXISTS currency;

-- ── Verify ─────────────────────────────────────────────────────────────────
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('cart_items', 'products')
ORDER BY table_name, ordinal_position;
