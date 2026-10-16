# Project charter

## Purpose

Simulate an end-to-end development and deployment cycle using Node.js, Docker Swarm, Jenkins, a local registry, Portainer, and separate DEV/QA/PROD-style environments.

## Portfolio value

The lab demonstrates DevOps concepts often encountered in existing enterprise environments: Jenkins pipelines, manual promotion gates, image registries, container orchestration, stack definitions, health checks, and deployment scripts. It is a useful legacy-platform counterpart to a Kubernetes-focused lab.

## Current scope

- Node/Express sample application with unit and integration-test structure.
- Docker Swarm stack files for simulated DEV, QA, and PROD environments.
- Jenkins pipeline stages for build, test, image push, deployment, approval, and smoke checks.
- Local registry, Portainer, initialization, deployment, cleanup, and WSL helper scripts.

## Outside current scope

- A multi-host production Swarm cluster, real application workload, or managed infrastructure.
- Secure external exposure, secrets lifecycle, robust CI agents, disaster-recovery validation, or support operations.
- A Kubernetes replacement or migration implementation.
