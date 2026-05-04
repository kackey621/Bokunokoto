[![Netlify Status](https://api.netlify.com/api/v1/badges/15896a7e-a561-4889-b619-89c454317dcf/deploy-status)](https://app.netlify.com/projects/my-profile-pj-docs/deploys)

# MyProfile-Webpages-Kusama

A personal profile and self-introduction site for people who want to learn more about me.

## About

This is a personal profile webpage application built with Ruby on Rails 8.1.3.

## Getting Started

### Requirements

* Ruby 3.2.3
* SQLite3

### Setup

```bash
bundle install
bin/rails db:setup
```

### Running the application

```bash
bin/dev
```

### Running tests

```bash
bin/rails test
bin/rails test:system
```

## Deployment

This application uses [Kamal](https://kamal-deploy.org/) for deployment. See `config/deploy.yml` for configuration.
