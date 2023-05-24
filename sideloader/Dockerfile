FROM golang:1.20-alpine AS build
WORKDIR /app
RUN apk update && apk add --no-cache git ca-certificates && update-ca-certificates
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /sideloader

FROM scratch AS app
WORKDIR /
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /sideloader /sideloader
ENTRYPOINT ["/sideloader"]
