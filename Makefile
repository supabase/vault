PG_CFLAGS = -std=c99 -Werror -Wno-declaration-after-statement
EXTENSION = supabase_vault
EXTVERSION = 0.3.1

DATA = $(wildcard sql/*--*.sql)

TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --use-existing --inputdir=test

MODULE_big = $(EXTENSION)
OBJS = $(patsubst %.c,%.o,$(wildcard src/*.c))

all: $(EXTENSION).control

$(EXTENSION).control:
	sed "s/@VAULT_VERSION@/$(EXTVERSION)/g" $(EXTENSION).control.in > $(EXTENSION).control

PG_CONFIG = pg_config
SHLIB_LINK = -lsodium

PG_CPPFLAGS := $(CPPFLAGS) -DEXTVERSION=\"$(EXTVERSION)\"

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
