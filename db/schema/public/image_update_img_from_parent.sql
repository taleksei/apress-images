CREATE OR REPLACE FUNCTION image_update_img_from_parent() returns trigger AS $$
BEGIN
  EXECUTE format(
    'SELECT processing, img_fingerprint, img_content_type, img_file_size, img_file_name FROM %I.%I WHERE id = %L',
    TG_TABLE_SCHEMA,
    TG_TABLE_NAME,
    NEW.fingerprint_parent_id
  ) INTO NEW.processing, NEW.img_fingerprint, NEW.img_content_type, NEW.img_file_size, NEW.img_file_name;

  RETURN NEW;
END
$$ LANGUAGE 'plpgsql';
