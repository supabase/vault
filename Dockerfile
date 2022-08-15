FROM testtag
RUN apt-get update && apt-get install -y make git postgresql-server-dev-14 postgresql-14-pgtap
RUN mkdir "/vault"
WORKDIR "/vault"
COPY . .
RUN make && make install

