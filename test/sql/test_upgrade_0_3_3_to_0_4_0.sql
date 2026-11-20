
DROP EXTENSION supabase_vault;
CREATE EXTENSION supabase_vault VERSION '0.3.2';

INSERT INTO vault.secrets (id, name, description, secret, nonce)
VALUES ('10e9080a-4c1e-4aaf-81b4-999eafffab27', 'a_name', 'this is the foo secret key', 'JwHHnjKHqFSJjpqbVgPs9iJ6Z+6mjJAH1nXpV2NT6U5FGTPsjMINZctT', '\xdd6c7de089774a0e4051de7281c6c4d4');

ALTER EXTENSION supabase_vault UPDATE;

SELECT decrypted_secret FROM vault.decrypted_secrets;
