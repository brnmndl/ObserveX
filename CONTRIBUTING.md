# Contributing to ObserveX

Thank you for your interest in contributing to ObserveX! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/ObserveX.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit your changes: `git commit -m "Description of changes"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Open a Pull Request

## Development Setup

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- Make (optional, for convenience commands)

### Running Locally

```bash
# Start the stack
make up
# or
docker compose up -d

# View logs
make logs
# or
docker compose logs -f

# Stop the stack
make down
# or
docker compose down
```

## Project Structure

```
ObserveX/
├── config/                    # Configuration files
│   ├── grafana/              # Grafana provisioning
│   │   └── provisioning/
│   │       ├── datasources/  # Datasource definitions
│   │       └── dashboards/   # Dashboard definitions
│   ├── otel-collector-config.yml  # OpenTelemetry Collector config
│   ├── prometheus.yml        # Prometheus config
│   ├── loki-config.yml       # Loki config
│   └── tempo-config.yml      # Tempo config
├── examples/                  # Example applications
├── helm/                      # Helm charts (future)
├── argocd/                    # ArgoCD manifests (future)
├── docker-compose.yml         # Docker Compose configuration
├── Makefile                   # Convenience commands
└── README.md                  # Documentation
```

## Types of Contributions

### Bug Reports
- Use the issue tracker
- Provide detailed reproduction steps
- Include version information
- Add relevant logs

### Feature Requests
- Open an issue first to discuss
- Explain the use case
- Consider implementation approach

### Code Contributions
- Follow existing code style
- Test your changes
- Update documentation
- Keep commits focused and atomic

### Documentation
- Fix typos and improve clarity
- Add examples
- Update outdated information

## Configuration Guidelines

### Adding New Services
1. Add service to `docker-compose.yml`
2. Create configuration file in `config/`
3. Update README with new service information
4. Add to Grafana datasources if applicable
5. Test integration with existing services

### Modifying Configurations
1. Test changes locally
2. Document why the change is needed
3. Consider backward compatibility
4. Update relevant documentation

## Testing

### Manual Testing
1. Start the stack: `make up`
2. Verify all services are healthy: `make status`
3. Check Grafana is accessible: http://localhost:3000
4. Send test telemetry data
5. Verify data appears in Grafana

### Configuration Validation
```bash
# Validate docker-compose.yml
make validate

# Check for syntax errors in YAML files
yamllint config/*.yml
```

## Code Style

### YAML Files
- Use 2 spaces for indentation
- Keep lines under 120 characters
- Use comments for complex configurations
- Order keys alphabetically when reasonable

### Documentation
- Use Markdown for all documentation
- Include code examples
- Keep language clear and concise
- Add links to relevant resources

## Commit Messages

Follow conventional commit format:

```
type(scope): subject

body (optional)

footer (optional)
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `config`: Configuration changes
- `refactor`: Code refactoring
- `test`: Test additions or changes
- `chore`: Maintenance tasks

Examples:
```
feat(otel): add Jaeger receiver support
fix(prometheus): correct scrape interval configuration
docs(readme): add troubleshooting section
config(loki): increase retention period to 14 days
```

## Pull Request Process

1. Update README.md with details of changes if needed
2. Update configuration documentation
3. Ensure docker-compose.yml is valid
4. Test the full stack with your changes
5. Request review from maintainers

### PR Checklist
- [ ] Changes are focused and minimal
- [ ] Configuration files are valid
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] All services start successfully
- [ ] No breaking changes (or clearly documented)

## Future Development

### Kubernetes/Helm
When contributing to Helm charts:
- Follow Helm best practices
- Support multiple environments
- Make configurations parameterized
- Include helpful comments

### ArgoCD
When contributing ArgoCD manifests:
- Follow GitOps principles
- Support multiple environments
- Include sync policies
- Document deployment process

## Questions?

- Open an issue for questions
- Tag with `question` label
- Be specific about what you're trying to achieve

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).
