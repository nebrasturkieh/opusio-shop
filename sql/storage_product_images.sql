-- =============================================================
-- Storage: product-images bucket + RLS policies
-- Run once in Supabase SQL editor.
-- Requires: public.is_admin() already exists (admin_rls_policies.sql)
-- =============================================================

-- 1. Create the bucket (public = URLs readable without auth token)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  5242880,          -- 5 MB max per file
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- 2. Path structure enforced by convention (not policy):
--    products/{product_id}/{uid}.{ext}          ← product cover
--    products/new/{uid}.{ext}                   ← product being created
--    variants/{variant_id}/{uid}.{ext}          ← variant cover
--    variants/new/{uid}.{ext}                   ← variant being created
--    variants/{variant_id}/gallery/{uid}.{ext}  ← variant gallery images

-- 3. Policies
-- Drop before re-create for idempotency
DROP POLICY IF EXISTS "product_images_admin_upload"  ON storage.objects;
DROP POLICY IF EXISTS "product_images_public_read"   ON storage.objects;
DROP POLICY IF EXISTS "product_images_admin_delete"  ON storage.objects;

-- Admins can upload to the bucket
CREATE POLICY "product_images_admin_upload"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND public.is_admin()
  );

-- Anyone (including anonymous visitors) can read public image URLs
CREATE POLICY "product_images_public_read"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'product-images');

-- Admins can delete any image in the bucket
-- NOTE: if you later add per-uploader ownership, replace is_admin()
-- with: (owner = auth.uid() AND public.is_admin())
CREATE POLICY "product_images_admin_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'product-images'
    AND public.is_admin()
  );
