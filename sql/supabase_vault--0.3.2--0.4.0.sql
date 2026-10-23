ALTER FUNCTION vault.create_secret SECURITY INVOKER;
ALTER FUNCTION vault.update_secret SECURITY INVOKER;

GRANT ALL ON FUNCTION
  vault._crypto_aead_det_encrypt,
  vault._crypto_aead_det_decrypt,
  vault._crypto_aead_det_noncegen,
  vault.create_secret,
  vault.update_secret
TO PUBLIC;
