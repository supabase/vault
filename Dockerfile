FROM rockylinux:9

RUN dnf --assumeyes update
RUN dnf --assumeyes install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
RUN dnf config-manager --enable crb

# install non postgres stuff
RUN dnf install --assumeyes make
RUN dnf install --assumeyes gcc
RUN dnf install --assumeyes libsodium
RUN dnf install --assumeyes libsodium-devel
RUN dnf install --assumeyes redhat-rpm-config
RUN dnf install --assumeyes clang
RUN dnf install --assumeyes sudo
RUN dnf install --assumeyes llvm-devel

RUN dnf install --assumeyes https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-$(uname -m)/pgdg-redhat-repo-latest.noarch.rpm

# install postgres stuff
RUN dnf install --assumeyes postgresql17-devel
RUN dnf install --assumeyes postgresql17-server
RUN dnf install --assumeyes pgtap_17

# setup vault user
RUN useradd vault
RUN echo 'vault ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

USER vault
ENV PATH=/usr/pgsql-17/bin/:${PATH}
WORKDIR /home/vault/vault
ENTRYPOINT ["bash"]
CMD ["-c", "echo 'echo 0000000000000000000000000000000000000000000000000000000000000000' > /tmp/vault_getkey.sh; chmod +x /tmp/vault_getkey.sh; cd /home/vault/vault; PATH=/usr/pgsql-17/bin/:$PATH make; sudo PATH=/usr/pgsql-17/bin/:$PATH make install; sudo chown -R vault /home/vault/vault; PATH=/usr/pgsql-17/bin/:$PATH make installcheck REGRESS_OPTS='--inputdir=test --temp-instance=temp --temp-config=./test/init.conf'"]

