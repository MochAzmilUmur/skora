# ============================================
# Stage 1: Builder — compile the Go binary
# ============================================
FROM golang:1.25-alpine AS builder

# Install git & ca-certificates (needed for fetching modules over HTTPS)
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copy dependency files first for better Docker layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build a statically linked binary (CGO disabled)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o /app/server ./main.go

# ============================================
# Stage 2: Runtime — minimal production image
# ============================================
FROM alpine:3.21

# Install ca-certificates for HTTPS calls and tzdata for timezone support
RUN apk add --no-cache ca-certificates tzdata

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/server .

# Create storage directory (for file uploads, etc.)
RUN mkdir -p /app/storage && chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Run the server
CMD ["./server"]
