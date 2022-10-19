FROM supabase/postgres:14.1.0.61
RUN apt-get update && apt-get install -y make git postgresql-server-dev-14 postgresql-14-pgtap
RUN mkdir "/vault"
WORKDIR "/vault"
COPY . .
RUN make && make install

