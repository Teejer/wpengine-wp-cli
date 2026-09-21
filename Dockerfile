FROM alpine:3.20

RUN apk add --no-cache \
        bash \
        curl \
        openssh-client \
        mysql-client \
        less \
        patch \
        diffutils \
        php83 \
        php83-phar \
        php83-mbstring \
        php83-xml \
        php83-curl \
        php83-openssl \
        php83-zip \
        php83-mysqli \
        php83-xmlwriter \
        php83-dom \
        php83-iconv \
        php83-fileinfo \
        php83-ftp \
        php83-gd \
        php83-intl \
        php83-sodium \
        composer \
    && ln -s /usr/bin/php83 /usr/local/bin/php \
    && curl -fsSL -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh \
    && printf '%s\n' \
        'Host *.ssh.wpengine.net' \
        '  PreferredAuthentications publickey' \
        '  IdentityFile /root/.ssh/wpengine_ed25519' \
        '  IdentitiesOnly yes' \
        > /root/.ssh/config \
    && chmod 600 /root/.ssh/config

WORKDIR /work

ENTRYPOINT ["wp"]
CMD ["--info"]
