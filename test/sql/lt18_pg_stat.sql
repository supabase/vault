SELECT * FROM vault.pg_stat_vault_reset();

do $$
begin
  perform vault.create_secret('s3kr3t_k3y', 'b_name', 'this is the foo secret key');
end
$$;

SELECT encryption_count, decryption_count FROM vault.pg_stat_vault();

SELECT decrypted_secret, description
FROM vault.decrypted_secrets WHERE name = 'b_name';
SELECT encryption_count, decryption_count FROM vault.pg_stat_vault();
SELECT * FROM vault.pg_stat_vault_reset();
SELECT encryption_count, decryption_count FROM vault.pg_stat_vault();

