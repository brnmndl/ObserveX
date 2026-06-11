# MySQL - Relational Database

MySQL database service configured for the ObserveX platform.

## Features

- **MySQL 8.0**: Latest stable MySQL version
- **Persistent Storage**: Data persists in Docker volume
- **Health Checks**: Built-in health monitoring
- **Pre-configured Database**: Ready-to-use `observex` database

## Running with Docker

```bash
# Start MySQL
docker-compose up -d

# View logs
docker-compose logs -f mysql

# Stop services
docker-compose down

# Stop and remove data
docker-compose down -v
```

MySQL will be available at: `localhost:3306`

## Credentials

Credentials are managed in the `.env` file

## Connection Examples

### MySQL CLI

```bash
# Connect as root
mysql -h localhost -u root -p
# Enter password: rootpassword

# Connect as dbuser
mysql -h localhost -u dbuser -p observex
# Enter password: dbpassword
```

### From Docker Container

```bash
docker exec -it mysql mysql -u root -prootpassword -e "SHOW DATABASES;"
```

### Connection String

```
mysql://dbuser:dbpassword@localhost:3306/observex
```

## Health Check

```bash
# Check MySQL health
docker exec mysql mysqladmin ping -h localhost -u root -prootpassword

# Expected response:
# mysqld is alive
```

## Directory Structure

```
mysql/
├── docker-compose.yml   # MySQL service configuration
├── .env                 # Environment variables (credentials)
└── README.md            # This file
```

## Data Storage

MySQL data is stored in the `mysql_data` Docker volume and persists between container restarts.

To backup data:
```bash
docker exec mysql mysqldump -u root -prootpassword observex > backup.sql
```

To restore data:
```bash
docker exec -i mysql mysql -u root -prootpassword observex < backup.sql
```

## Useful Commands

```bash
# List all databases
docker exec mysql mysql -u root -prootpassword -e "SHOW DATABASES;"

# Show users
docker exec mysql mysql -u root -prootpassword -e "SELECT user, host FROM mysql.user;"

# Create a new database
docker exec mysql mysql -u root -prootpassword -e "CREATE DATABASE newdb;"

# Create a new user
docker exec mysql mysql -u root -prootpassword -e "CREATE USER 'newuser'@'%' IDENTIFIED BY 'newpass'; GRANT ALL PRIVILEGES ON newdb.* TO 'newuser'@'%'; FLUSH PRIVILEGES;"
```

## Troubleshooting

### Connection Refused

- Ensure MySQL container is running: `docker ps`
- Check if port 3306 is already in use: `lsof -i :3306`
- Check logs: `docker-compose logs mysql`

### Permission Denied

- Verify username and password
- Ensure user has necessary privileges

### Container Won't Start

```bash
# View detailed logs
docker-compose logs mysql

# Remove volume and restart (WARNING: data loss)
docker-compose down -v
docker-compose up -d
```
