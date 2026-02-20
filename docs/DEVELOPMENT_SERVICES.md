# Development Services Guide

This NixOS config includes declarative development services via `services-flake` and `process-compose-flake`.

## Available Services

### PostgreSQL (Local Development)

**Service**: `dev-services`
**Start**: `nix run .#dev-services` (press F7 to start)
**Connection**: `localhost:5432`
**User**: `postgres` (no password)
**Data**: `./data/pg1/` (persisted)

### PostgreSQL (Web Projects)

**Service**: `web-db`
**Start**: `nix run .#web-db`
**Connection**: `localhost:5432`
**User**: `postgres`
**Data**: `./data/web-db/` (persisted)

## Usage

### Starting Services

```bash
# Interactive TUI (recommended)
nix run .#dev-services

# Press F7 to start all services
# Press Ctrl+C to stop
```

### Adding Services

Edit `flake-modules/services.nix`:

```nix
process-compose."my-services" = {
  services.redis.r1 = {
    enable = true;
    port = 6379;
  };
};
```

Available services: PostgreSQL, MySQL, Redis, MongoDB, Kafka, and [30+ more](https://community.flake.parts/services-flake).

## Data Persistence

Service data is stored in `./data/<service-name>/`:
- **Persisted**: Survives restarts, safe to commit to version control (ignored by .gitignore)
- **Location**: Relative to where you run `nix run .#service`
- **Clean**: `rm -rf ./data/` to reset all services

## References

- [services-flake documentation](https://community.flake.parts/services-flake)
- [process-compose-flake](https://community.flake.parts/process-compose-flake)
