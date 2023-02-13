FROM postgres:15

# Basic dependencies
RUN apt update && apt upgrade && apt install -y curl jq tree wget

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq

# Use the inherited entrypoint and command
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 5432
CMD ["postgres"]
