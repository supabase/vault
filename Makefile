EXTENSION = supabase_vault
DATA = $(wildcard sql/*--*.sql)
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
