FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install build dependencies for CGO
RUN apk add --no-cache gcc musl-dev sqlite-dev

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=1 GOOS=linux go build -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates sqlite

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/main .
COPY --from=builder /app/static ./static

# Create data and logs directories
RUN mkdir -p /app/data /app/logs

# Expose port
EXPOSE 8907

# Run the application
CMD ["./main"]
