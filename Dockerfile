FROM --platform=linux/amd64 postgres:15-bullseye

ARG BOOTLEG_VER=0.1.9

# Basic dependencies
RUN apt update && apt upgrade -y && apt install -y curl jq tree wget
RUN apt install -y git

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

# Use the inherited entrypoint and command
COPY ./initdb /docker-entrypoint-initdb.d
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 5432
CMD ["postgres"]
