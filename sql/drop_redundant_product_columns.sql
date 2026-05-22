-- Drop redundant product-level columns that have been superseded by product_variants.
-- price_cents  → product_variants.price_cents
-- stock_quantity → product_variants.stock_quantity
-- material     → product_variants.material_type / material_color

alter table products
  drop column if exists price_cents,
  drop column if exists stock_quantity,
  drop column if exists material;
