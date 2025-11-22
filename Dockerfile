FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY . .

RUN go get github.com/lib/pq
RUN go get github.com/armon/go-socks5
RUN go mod tidy

RUN CGO_ENABLED=0 GOOS=linux go build -o proxyer main.go

FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/proxyer .

EXPOSE 8080

CMD ["./proxyer"]
