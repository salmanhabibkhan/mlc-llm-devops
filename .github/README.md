# MLC-LLM CI/CD Pipeline

This repository uses a fully modular and reusable GitHub Actions workflow system:

### Workflows
- `ci-cd.yml` — Main CI pipeline
- `release.yml` — Release pipeline triggered by version tags
- `docker-build.yml` — Reusable Docker builder
- `wheel-build.yml` — Reusable wheel builder
- `test.yml` — Reusable test suite
- `validate.yml` — Reusable code validation

### Scripts
Located in `scripts/` for Linux and Windows.

### CMake Templates
`wheel-config.cmake` is injected into wheel builds.
