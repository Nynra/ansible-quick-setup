# Docker

Ansible role for installing, configuring, and maintaining Docker.

- [Rootless Docker](https://docs.docker.com/engine/security/rootless/)

The role performs these tasks:

- Install Docker via the official convenience script (skipped if already installed)
- Add the connecting user to the `docker` group
- Optionally deploy `/etc/docker/daemon.json` from a template
- Start and enable the `docker` service
- Pull a list of images
- Optionally prune unused containers, images, networks, volumes and build cache

## Variables

- `docker_install` (default: `true`) - install Docker if not already present
- `docker_configure_daemon` (default: `false`) - deploy `/etc/docker/daemon.json`
- `docker_data_root` (default: `/var/lib/docker`)
- `docker_metrics_host` (default: `127.0.0.1`)
- `docker_metrics_port` (default: `9323`)
- `docker_images` (default: `[]`) - list of images to pull after install
- `docker_prune_enabled` (default: `false`) - run pruning tasks
- `docker_prune_containers` (default: `true`) - prune stopped containers
- `docker_prune_images` (default: `true`) - prune unused images
- `docker_prune_images_all` (default: `false`) - prune all unused images, not just dangling ones
- `docker_prune_networks` (default: `true`) - prune unused networks
- `docker_prune_volumes` (default: `false`) - prune unused volumes, destructive, disabled by default
- `docker_prune_builder_cache` (default: `true`) - prune the build cache

## Example

```yaml
- hosts: all
  collections:
    - structam.general_server_management
  tasks:
    - import_role:
        name: docker
      vars:
        docker_images:
          - "hello-world:latest"
        docker_prune_enabled: true
        docker_prune_volumes: false
```
