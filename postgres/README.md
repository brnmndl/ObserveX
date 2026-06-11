# PostgreSQL - Relational Database

PostgreSQL database service configured for the ObserveX platform.

## Features

- **PostgreSQL 16**: Latest stable PostgreSQL version
- **Persistent Storage**: Data persists in Docker volume
- **Health Checks**: Built-in health monitoring
- **Pre-configured Database**: Ready-to-use `observex` database

## Running with Docker

```bash
# Start PostgreSQL
docker-compose up -d

# View logs
docker-compose logs -f postgres

# Stop services
docker-compose down

# Stop and remove data
docker-compose down -v
```

PostgreSQL will be available at: `localhost:5432`

## Credentials

Credentials are managed in the `.env` file

## Connection Examples

### PostgreSQL CLI

```bash
# Connect to the database
psql -h localhost -U dbuser -d observex
# Enter password: dbpassword

# Connect as superuser
psql -h localhost -U postgres
```

### From Docker Container

```bash
docker exec -it postgres psql -U dbuser -d observex -c "SELECT version();"
```

### Connection String

```
postgresql://dbuser:dbpassword@localhost:5432/observex
```

## Health Check

```bash
# Check PostgreSQL health
docker exec postgres pg_isready -U dbuser

# Expected response:
# accepting connections
```

## Directory Structure

```
postgres/
├── docker-compose.yml   # PostgreSQL service configuration
├── .env                 # Environment variables (credentials)
└── README.md            # This file
```

## Data Storage

PostgreSQL data is stored in the `postgres_data` Docker volume and persists between container restarts.

To backup data:
```bash
docker exec postgres pg_dump -U dbuser observex > backup.sql
```

To restore data:
```bash
docker exec -i postgres psql -U dbuser observex < backup.sql
```

## Useful Commands

```bash
# List all databases
docker exec postgres psql -U dbuser -d observex -c "\l"

# List all users
docker exec postgres psql -U dbuser -d observex -c "\du"

# Create a new database
docker exec postgres psql -U postgres -c "CREATE DATABASE newdb;"

# Create a new user
docker exec postgres psql -U postgres -c "CREATE USER newuser WITH PASSWORD 'newpass'; GRANT ALL PRIVILEGES ON DATABASE newdb TO newuser;"

# Connect to a database and run a query
docker exec postgres psql -U dbuser -d observex -c "SELECT * FROM information_schema.tables WHERE table_schema = 'public';"
```

## Troubleshooting

### Connection Refused

- Ensure PostgreSQL container is running: `docker ps`
- Check if port 5432 is already in use: `lsof -i :5432`
- Check logs: `docker-compose logs postgres`

### Permission Denied

- Verify username and password
- Ensure user has necessary privileges

### Container Won't Start

```bash
# View detailed logs
docker-compose logs postgres

# Remove volume and restart (WARNING: data loss)
docker-compose down -v
docker-compose up -d
```

## Extensions

To enable PostgreSQL extensions, add an initialization script. For example, to enable PostGIS for geospatial queries, create an `init.sql`:

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
```

Then mount it in docker-compose.yml:

```yaml
volumes:
  - ./init.sql:/docker-entrypoint-initdb.d/init.sql
  - postgres_data:/var/lib/postgresql/data
```
