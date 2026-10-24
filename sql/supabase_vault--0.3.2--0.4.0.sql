ALTER FUNCTION vault.create_secret SECURITY INVOKER;
ALTER FUNCTION vault.update_secret SECURITY INVOKER;

-- check which users were granted vault.update_secret then
-- grant update/delete on table `vault.secrets` to user
DO $$
DECLARE
    user_record RECORD;
BEGIN

    FOR user_record IN 
	SELECT 
		grantor, 
		grantee,
		CASE 
			when is_grantable = 'YES' THEN 'WITH GRANT OPTION'
			else ''
		END AS grantable
	FROM information_schema.routine_privileges 
	WHERE specific_name in (
			SELECT proname || '_' || oid 
			FROM pg_proc 
			WHERE proname = 'update_secret' 
				AND proargnames = '{secret_id,new_secret,new_name,new_description,new_key_id}'
		)
		AND routine_schema  = 'vault'
		AND grantee NOT IN (SELECT rolname FROM pg_roles where rolsuper)

    LOOP
        EXECUTE format('SET ROLE %s;', user_record.grantor);
        EXECUTE format('GRANT update on table vault.secrets TO %s %s GRANTED BY %s;', user_record.grantee, user_record.grantable, user_record.grantor);
        EXECUTE format('RESET ROLE;');
    END LOOP;
END $$;

-- check which users were granted vault.create_secret then
-- grant insert on table `vault.secrets` to user
DO $$
DECLARE
    user_record RECORD;
BEGIN

    FOR user_record IN 
	SELECT 
		grantor, 
		grantee,
		CASE 
			when is_grantable = 'YES' THEN 'WITH GRANT OPTION'
			else ''
		END AS grantable
	FROM information_schema.routine_privileges 
	WHERE specific_name in (
			SELECT proname || '_' || oid 
			FROM pg_proc 
			WHERE proname = 'create_secret' 
				AND proargnames = '{new_secret,new_name,new_description,new_key_id}'
		)
		AND routine_schema  = 'vault' 
		AND grantee NOT IN (SELECT rolname FROM pg_roles where rolsuper)
    LOOP
        EXECUTE format('SET ROLE %s;', user_record.grantor);
        EXECUTE format('GRANT insert on table vault.secrets TO %s %s GRANTED BY %s', user_record.grantee, user_record.grantable, user_record.grantor);
        EXECUTE format('RESET ROLE;');

    END LOOP;
END $$;


GRANT ALL ON FUNCTION
  vault._crypto_aead_det_encrypt,
  vault._crypto_aead_det_decrypt,
  vault._crypto_aead_det_noncegen,
  vault.create_secret,
  vault.update_secret
TO PUBLIC;

