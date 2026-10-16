# Current architecture

```text
Developer / Git
      |
      v
Jenkins pipeline -> local registry
      |                 |
      |                 v
      +--> DEV Swarm stack (automatic)
      +--> QA Swarm stack  (approval gate)
      +--> PROD Swarm stack (approval gate)
                 |
                 v
            Portainer views
```

The lab supplies scripts and stack definitions that simulate isolated environments on a local Docker/WSL setup. Jenkins builds and tests the example Node app, publishes an image to a local registry, then deploys environment-specific stacks with manual QA/PROD gates.

## Boundary

Environment labels, replica counts, and approval steps are teaching mechanisms in a single-host simulation. They do not by themselves provide production isolation, high availability, security, release governance, or recovery guarantees.
