FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

#RUN echo 'deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse\n' > /etc/apt/sources.list

RUN apt-get upgrade
RUN set -ex; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        dbus-x11 \
        nautilus \
        gedit \
        expect \
        sudo \
        vim \
	vlc \
        bash \
        net-tools \
        novnc \
        xfce4 \
	socat \
        x11vnc \
	xvfb \
        supervisor \
        curl \
        git \
	pulseaudio \
        wget \
        g++ \
	unzip \
        ssh \
	ffmpeg \
	chromium-browser \
	firefox \
        terminator \
        htop \
        gnupg2 \
	locales \
	xfonts-intl-chinese \
	fonts-wqy-microhei \  
	ibus-pinyin \
	ibus \
	ibus-clutter \
	ibus-gtk \
	ibus-gtk3 \
	ibus-qt4 \
	openssh-server \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
RUN dpkg-reconfigure locales

RUN sudo apt-get update && sudo apt-get install -y obs-studio

COPY . /app
RUN chmod +x /app/conf.d/websockify.sh
RUN chmod +x /app/run.sh
RUN chmod +x /app/expect_vnc.sh
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list
RUN echo "deb http://deb.anydesk.com/ all main"  >> /etc/apt/sources.list
RUN wget --no-check-certificate https://dl.google.com/linux/linux_signing_key.pub -P /app
RUN wget --no-check-certificate -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY -O /app/anydesk.key
RUN apt-key add /app/anydesk.key
RUN apt-key add /app/linux_signing_key.pub
RUN set -ex; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        google-chrome-stable \
	anydesk


ENV UNAME pacat

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --yes pulseaudio-utils

# Set up the user
RUN export UNAME=$UNAME UID=1000 GID=1000 && \
    mkdir -p "/home/${UNAME}" && \
    echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd && \
    echo "${UNAME}:x:${UID}:" >> /etc/group && \
    mkdir -p /etc/sudoers.d && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} && \
    chmod 0440 /etc/sudoers.d/${UNAME} && \
    chown ${UID}:${GID} -R /home/${UNAME} && \
    gpasswd -a ${UNAME} audio

RUN echo xfce4-session >~/.xsession
RUN echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" 

CMD ["/app/run.sh"]



FROM alpine:latest

WORKDIR /usr/local/

RUN apk update && \
    apk add --no-cache tzdata python3 runit py3-pip && \
    apk add --no-cache --virtual .build-deps git gcc linux-headers musl-dev python3-dev && \
    git clone --single-branch --branch master --depth=1 https://github.com/sola97/v2-ui.git && \
    cd v2-ui && \
    chmod +x bin/xray-v2-ui /usr/local/v2-ui/v2-ui.sh && \
    python3 -m pip install --disable-pip-version-check --ignore-installed --no-cache-dir --quiet -r /usr/local/v2-ui/requirements.txt  && \
    apk del .build-deps git gcc linux-headers musl-dev python3-dev && \
    mkdir -p /etc/v2-ui/ && \
    mkdir -p /var/log/v2ray/ && \
    touch /etc/v2-ui/v2-ui.db && \
    touch /etc/v2-ui/v2-ui.log && \
    touch /var/log/v2ray/access.log && \
    touch /var/log/v2ray/error.log && \
    ln -sf /usr/local/v2-ui/v2-ui.sh /usr/bin/v2-ui.sh && \
    ln -sf /dev/stdout /etc/v2-ui/v2-ui.log && \
    ln -sf /dev/stdout /var/log/v2ray/access.log && \
    ln -sf /dev/stderr /var/log/v2ray/error.log

COPY runit /etc/service
CMD [ "runsvdir", "-P", "/etc/service"]
