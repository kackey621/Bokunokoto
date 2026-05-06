[![Netlify Status](https://api.netlify.com/api/v1/badges/15896a7e-a561-4889-b619-89c454317dcf/deploy-status)](https://app.netlify.com/projects/my-profile-pj-docs/deploys)

# MyProfile-Webpages-Kusama

A personal profile and self-introduction backend for people who want to learn more about me.

## About

This is a Ruby on Rails 8.1.3 backend. The SPA/Flutter Web client is hosted separately, while Rails serves the JSON API, system console, Sidekiq workers, MySQL-backed data, Redis-backed jobs, and development email capture.

## Getting Started

### Requirements

* Ruby 3.3.7
* Docker Desktop
* MySQL 8.4
* Redis 7

### Docker setup

```bash
docker compose up --build
```

Rails starts on:

```text
http://localhost:3000
```

If port 3000 is already in use:

```bash
RAILS_PORT=3002 docker compose up --build
```

Useful local endpoints:

```text
http://localhost:3000/up
http://localhost:3000/api/v1/health
http://localhost:3000/console
http://localhost:3000/console/users
http://localhost:8025
```

The Rails system console uses the MIT-licensed CoreUI Free Bootstrap Admin Template structure and locally vendored CoreUI assets for the sidebar, header, cards, tables, forms, and operational control layout. CoreUI is installed through npm and served by Rails from `vendor/assets/coreui`, so the console does not depend on a CDN.

### Local services

The Docker stack runs:

* `web` — Rails API and system console
* `sidekiq` — Active Job worker
* `mysql` — MySQL 8.4
* `redis` — Sidekiq and Rails infrastructure
* `mailpit` — local email capture

The SPA/Flutter Web client is not served by this repository. Configure it to call:

```text
http://localhost:3000/api/v1
```

Allowed browser origins are controlled with:

```bash
FRONTEND_ORIGINS=http://localhost:5173,http://localhost:3001
```

### Rails commands

```bash
docker compose exec web bin/rails db:prepare
docker compose exec web bin/rails test
docker compose exec web bin/rails console
```

### Running tests

```bash
docker compose exec web bin/rails test
docker compose exec web bin/rails test:system
```

## Deployment

This application uses [Kamal](https://kamal-deploy.org/) for deployment. See `config/deploy.yml` for configuration.
