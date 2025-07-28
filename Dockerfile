# syntax=docker/dockerfile:1

ARG BASE_IMAGE=python:3.14.0rc1-slim-bookworm


# Here is the production image
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

ARG GID=11000
ARG GROUP=certbot

ENV GID=${GID} \
	GROUP=${GROUP} \
	PYTHONIOENCODING=utf-8

WORKDIR /etc/letsencrypt

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Installing system dependencies
RUN rm -rfv /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /root/.cache/* && \
	apt-get clean -y && \
	apt-get update --fix-missing -o Acquire::CompressionTypes::Order::=gz && \
	apt-get install -y --no-install-recommends \
		locales \
		tzdata \
		procps \
		iputils-ping \
		iproute2 \
		curl \
		nano \
		tini \
		openssl \
		cron && \
		# libaugeas0 && \
	apt-get clean -y && \
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
	sed -i -e 's/# en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/' /etc/locale.gen && \
	sed -i -e 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=en_US.UTF-8 && \
	echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale && \
	echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale && \
	addgroup --gid "${GID}" "${GROUP}" && \
	# useradd -lmN -d "/home/${USER}" -s /bin/bash -g "${GROUP}" -G sudo -u "${UID}" "${USER}" && \
	echo -e "\nalias ls='ls -aF --group-directories-first --color=auto'" >> /root/.bashrc && \
	echo -e "alias ll='ls -alhF --group-directories-first --color=auto'\n" >> /root/.bashrc && \
	pip install --timeout 60 --no-cache-dir --upgrade pip && \
	pip install --timeout 60 --no-cache-dir certbot certbot-dns-cloudflare && \
	pip cache purge && \
	rm -rfv /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /root/.cache/* && \
	mkdir -pv /etc/letsencrypt/live /var/lib/letsencrypt /var/log/letsencrypt /var/www/.well-known/acme-challenge && \
	chown -Rc "www-data:${GROUP}" /var/www/.well-known && \
	find /var/www/.well-known /var/log/letsencrypt -type d -exec chmod -c 775 {} + && \
	find /var/www/.well-known /var/log/letsencrypt -type d -exec chmod -c +s {} + && \
	chown -Rc "1000:${GROUP}" /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt && \
	find /etc/letsencrypt /var/lib/letsencrypt -type d -exec chmod -c 770 {} + && \
	find /etc/letsencrypt /var/lib/letsencrypt -type d -exec chmod -c ug+s {} +

ENV	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=en_US.UTF-8

COPY --chown=root:root --chmod=770 ./scripts/docker/*.sh /usr/local/bin/

VOLUME ["/etc/letsencrypt"]

ENTRYPOINT ["docker-entrypoint.sh"]
