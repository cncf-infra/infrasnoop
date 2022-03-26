FROM postgres:12.7-buster as final
LABEL MAINTAINER="Hippie Hacker <hh@ii.coop>"
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  postgresql-13-plsh \
  postgresql-server-dev-13 \
  libpq-dev \
  wget \
  make \
  gcc \
  libc6-dev \
  curl \
  jq \
  git \
  software-properties-common \
  apt-transport-https
  # postgresql-plpython3-14 \
  # python3-pip \
  # python3-psycopg2 \
  # python3-ipdb \
  # python3-requests \
  # python3-yaml \
# I suspect we used these for advanced web scraping?
#  python3-bs4 \
#  firefox-esr \


# RUN python3 --version
# RUN pip3 install --upgrade pip
# RUN pip3 install --upgrade requests
# RUN pip3 install selenium webdriver-manager
# RUN wget "https://github.com/mozilla/geckodriver/releases/download/v0.29.1/geckodriver-v0.29.1-linux64.tar.gz" \
#     && tar xvf geckodriver* \
#     && chmod +x geckodriver \
#     && mv geckodriver /usr/local/bin

# RUN env PG_CONFIG=$(which pg_config) \
#     && git clone https://github.com/theory/pg-semver.git \
#     && cd pg-semver \
#     B
#     && make && make install


# RUN mkdir /tmp/coverage && chmod 777 /tmp/coverage
COPY initdb /docker-entrypoint-initdb.d
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
FROM golang:1.17.4-alpine as build-discovery-config-jobs
WORKDIR /app
COPY go.* *.go /app/
RUN go mod download
# COPY *go /app/
# COPY prow/config /app/prow/
# COPY experiment/infrasnoop/postgres/ /app/experiment/infrasnoop/postgres/
RUN CGO_ENABLED=0 GOOS=linux GOARCH="" go build \
  -a \
  -installsuffix cgo \
  -ldflags "-extldflags '-static' -s -w" \
  -o /app/bin/discovery-config-jobs \
  /app/main.go
# FROM postgres:14.2-bullseye
FROM final
COPY --from=build-discovery-config-jobs /app/bin/discovery-config-jobs /docker-entrypoint-initdb.d/501_discovery-config-jobs.elf
# ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "--user postgres"]
