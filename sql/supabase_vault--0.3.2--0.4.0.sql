ALTER FUNCTION vault.create_secret SECURITY INVOKER;
ALTER FUNCTION vault.update_secret SECURITY INVOKER;

-- check which users were granted vault.update_secret then
-- grant update/delete on table `vault.secrets` to user
DO $$
DECLARE
    user_record RECORD;
BEGIN

   -- TODO should we lock down routine by arg names? probably
    FOR user_record IN 
	SELECT grantor, grantee 
	FROM information_schema.routine_privileges 
	WHERE routine_schema  = 'vault' 
		AND routine_name = 'create_secret' 
		AND grantee NOT IN (SELECT rolname FROM pg_roles where rolsuper)

    LOOP
	-- TODO Should this cover 'with grant option'?
        EXECUTE format('GRANT insert on table vault.secrets %I GRANTED BY %I;', user_record.grantee, user_record.grantor);
    END LOOP;
END $$;

-- check which users were granted vault.create_secret then
-- grant insert on table `vault.secrets` to user
DO $$
DECLARE
    user_record RECORD;
BEGIN

   -- TODO should we lock down routine by arg names? probably
    FOR user_record IN 
	SELECT grantor, grantee 
	FROM information_schema.routine_privileges 
	WHERE routine_schema  = 'vault' 
		AND routine_name = 'update_secret' 
		AND grantee NOT IN (SELECT rolname FROM pg_roles where rolsuper)
    LOOP
	-- TODO Should this cover 'with grant option'?
        EXECUTE format('GRANT update on table vault.secrets TO %I GRANTED BY %I', user_record.grantee, user_record.grantor);

    END LOOP;
END $$;


GRANT ALL ON FUNCTION
  vault._crypto_aead_det_encrypt,
  vault._crypto_aead_det_decrypt,
  vault._crypto_aead_det_noncegen,
  vault.create_secret,
  vault.update_secret
TO PUBLIC;

