ALTER FUNCTION vault.create_secret SECURITY INVOKER;
ALTER FUNCTION vault.update_secret SECURITY INVOKER;

GRANT ALL ON FUNCTION
  vault._crypto_aead_det_encrypt,
  vault._crypto_aead_det_decrypt,
  vault._crypto_aead_det_noncegen,
  vault.create_secret,
  vault.update_secret
TO PUBLIC;

-- TODO check which users were granted vault.update_secret then
--      grant update/delete on table `vault.secrets` to user
SELECT rolname
FROM pg_roles
WHERE has_function_privilege(rolname, 'vault.update_secret(uuid, text, text, text, uuid)', 'execute') and not rolsuper;

-- TODO check which users were granted vault.create_secret then
--      grant insert on table `vault.secrets` to user
SELECT rolname
FROM pg_roles
WHERE has_function_privilege(rolname, 'vault.create_secret(text, text , text, uuid)', 'execute');


