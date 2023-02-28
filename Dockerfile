FROM --platform=linux/amd64 postgres:15-bullseye

ARG BOOTLEG_VER=0.1.9

# Basic dependencies
RUN apt update && apt upgrade -y && apt install -y curl jq tree wget
RUN apt install -y git

# Install babashka
RUN curl -sLO https://raw.githubusercontent.com/babashka/babashka/master/install && chmod +x install && ./install

# Install bootleg for web scraping
RUN wget https://github.com/retrogradeorbit/bootleg/releases/download/v$BOOTLEG_VER/bootleg-$BOOTLEG_VER-linux-amd64.tgz
RUN tar xvf bootleg-$BOOTLEG_VER-linux-amd64.tgz && \
    mv bootleg /usr/local/bin && \
    chown 0:0 root /usr/local/bin/bootleg && \
    chmod +x /usr/local/bin/bootleg

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

# Use the inherited entrypoint and command
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 5432
CMD ["postgres"]
