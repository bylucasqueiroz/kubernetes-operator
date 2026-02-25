FROM golang:1.26-alpine AS builder

WORKDIR /app

# dependências necessárias
RUN apk add --no-cache git

COPY go.mod .
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app .

# imagem final leve com alpine
FROM alpine:3.20

WORKDIR /app

# adicionar certificado raiz (importante para HTTPS / Kubernetes API)
RUN apk add --no-cache ca-certificates

COPY --from=builder /app/app .

USER nobody

ENTRYPOINT ["/app/app"]