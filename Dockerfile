FROM golang:1.20-bullseye AS build
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /shipped23

FROM debian:bullseye-slim AS release
WORKDIR /
COPY --from=build /shipped23 /shipped23
EXPOSE 8080
ENTRYPOINT ["/shipped23"]
