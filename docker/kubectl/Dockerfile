FROM ubuntu:24.04

RUN apt-get update
RUN apt-get -y install vim less tzdata curl gpg git
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg ; \
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get -y install kubectl

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

WORKDIR /tmp
RUN echo 'tzdata tzdata/Areas select Europe' > preseed.txt ; echo 'tzdata tzdata/Zones/Europe select Amsterdam' >> preseed.txt
RUN rm -f /etc/localtime /etc/timezone ; debconf-set-selections /tmp/preseed.txt ; dpkg-reconfigure tzdata

RUN curl -sS 'https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz' -o 'docker-24.0.6.tgz' ; \
        tar -xvzf docker-24.0.6.tgz ; \
        cp docker/docker /usr/bin/docker

## RUN groupadd -g 999 wsl ; mkdir /home/wsluser ; chown 999.wsl /home/wsluser ; useradd -u 999 -g wsl -d /home/wsluser wsluser -s /bin/bash
RUN groupadd -g 999 wsl || true
RUN usermod -a -G `getent group 999 | cut -d: -f1` ubuntu

RUN groupadd -g 101 docker || true
RUN usermod -a -G `getent group 101 | cut -d: -f1` ubuntu

ADD dot_bashrc.sh /home/ubuntu/.bashrc
## WORKDIR /root
WORKDIR /home/ubuntu
USER ubuntu
