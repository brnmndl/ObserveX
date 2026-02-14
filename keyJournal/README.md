# KeyJournal

A lightweight Go web application with tabbed interface for managing key-value pairs and generating timestamped logs.

## Features

- **Tabbed Interface**: Create, switch between, and delete tabs
- **Key-Value Pairs**: Add/edit/remove name-value pairs in each tab
- **Persistent Storage**: SQLite database saves all state
- **Logging**: Submit button generates JSON log entries with timestamp
- **Access Control**: Token-based access via Docker secrets
- **Lightweight**: Minimal dependencies, runs in Docker

## Running with Docker

```bash
# Build and start the application
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the application
docker-compose down
```

The application will be available at: http://localhost:8907

## Manual Build & Run

```bash
# Install dependencies
go mod download

# Run locally
go run main.go
```

## Usage

1. Click **"+ Add Tab"** to create a new tab
2. Add key-value pairs using the input fields
3. Click **"+ Add Pair"** to add more pairs
4. Click **"Save"** to persist changes to database
5. Click **"Submit & Log"** to save and generate a log entry

## Log Format

Logs are written to `./logs/app.log` in JSON format:
```
{"timestamp":"2026-02-13T14:41:58Z","currency":"sek","name":"abc","quotent":"9999999","tab_name":"Test"}
```

## Access Tokens (Docker Secrets)

Tokens are read from `keyJournal/secrets/keyjournal_tokens` and can be comma- or newline-separated.

Example:
```
token1
token2
token3
```

## Directory Structure

```
keyJournal/
├── main.go              # Go backend
├── static/
│   └── index.html       # Frontend UI
├── data/                # SQLite database
├── logs/                # Application logs
├── secrets/
│   └── keyjournal_tokens # Access tokens
├── Dockerfile
├── docker-compose.yml
└── go.mod
```
