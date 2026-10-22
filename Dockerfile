ARG BASE_IMAGE=rockylinux:9
FROM ${BASE_IMAGE}

RUN dnf --assumeyes update

RUN source /etc/os-release && \
	case "${ROCKY_SUPPORT_PRODUCT}" in \
		Rocky-Linux-10) \
			dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm \
			&& crb enable ;; \
		Rocky-Linux-9) \
			dnf --assumeyes install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
				&& dnf config-manager --enable crb ;; \
		Rocky-Linux-8) \
			dnf install --assumeyes https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
				&& dnf config-manager --enable powertools \
				&& dnf -qy module disable postgresql ;; \
	esac

# install non postgres stuff
RUN dnf install --assumeyes make
RUN dnf install --assumeyes gcc
RUN dnf install --assumeyes libsodium
RUN dnf install --assumeyes libsodium-devel
RUN dnf install --assumeyes redhat-rpm-config
RUN dnf install --assumeyes clang
RUN dnf install --assumeyes sudo
RUN dnf install --assumeyes llvm-devel

RUN source /etc/os-release && \
	case "${ROCKY_SUPPORT_PRODUCT}" in \
		Rocky-Linux-10) \
			dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-10-$(uname -m)/pgdg-redhat-repo-latest.noarch.rpm ;; \
		Rocky-Linux-9) \
			dnf install --assumeyes https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-$(uname -m)/pgdg-redhat-repo-latest.noarch.rpm ;; \
		Rocky-Linux-8) \
			dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-$(uname -m)/pgdg-redhat-repo-latest.noarch.rpm ;; \
	esac

# install postgres stuff
RUN dnf install --assumeyes postgresql17-devel
RUN dnf install --assumeyes postgresql17-server
RUN dnf install --assumeyes plpgsql_check_17

RUN echo 'postgres ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

USER postgres
ENV PATH=/usr/pgsql-17/bin/:${PATH}
WORKDIR /home/postgres/postgres
ENTRYPOINT ["bash"]
CMD ["-c", "echo 'echo 0000000000000000000000000000000000000000000000000000000000000000' > /tmp/vault_getkey.sh; chmod +x /tmp/vault_getkey.sh; cd /home/postgres/vault; sudo chown -R postgres /home/postgres/vault; PATH=/usr/pgsql-17/bin/:$PATH make; sudo PATH=/usr/pgsql-17/bin/:$PATH make install;  PATH=/usr/pgsql-17/bin/:$PATH make installcheck REGRESS_OPTS='--inputdir=test --temp-instance=temp --temp-config=./test/init.conf'"]

