FROM postgres:15
RUN apt-get update && apt-get install -y make build-essential curl git postgresql-server-dev-15 postgresql-15-pgtap
RUN curl -s -L https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz | tar zxvf - && cd libsodium-1.0.18 && ./configure && make check && make -j 4 install
RUN ldconfig
RUN git clone https://github.com/michelp/pgsodium.git && cd pgsodium && git checkout tags/v3.1.2 && make install
# RUN git clone https://github.com/michelp/pgsodium.git && cd pgsodium && git checkout main && make install
RUN mkdir "/vault"
WORKDIR "/vault"
COPY . .
RUN make && make install

