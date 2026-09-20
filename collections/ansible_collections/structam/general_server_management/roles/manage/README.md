# Management role

Simple Ansible role for package maintenance on Debian and Ubuntu.

The role performs these tasks:

- Update the apt package cache
- Run package upgrades (`dist` by default)
- Optionally run autoremove
- Reboot only when `/var/run/reboot-required` exists

## Variables

- `manage_update_cache` (default: `true`)
- `manage_cache_valid_time` (default: `3600`)
- `manage_upgrade` (default: `true`)
- `manage_upgrade_type` (default: `dist`)
- `manage_autoremove` (default: `true`)
- `manage_reboot_if_required` (default: `true`)
- `manage_reboot_timeout` (default: `900`)
- `manage_reboot_connect_timeout` (default: `5`)
- `manage_reboot_test_command` (default: `whoami`)

## Example

```yaml
- hosts: all
 collections:
  - structam.general_server_management
 tasks:
  - import_role:
    name: manage
```

## Runtime Profiles

In `ansible-server-management`, two variable profile files are available:

- `inventory/group_vars/examples/manage-safe.yml`
- `inventory/group_vars/examples/manage-full.yml`

Run with one of these profiles:

```bash
ansible-playbook -i inventory/local.yml playbooks/manage-system.yml -K -e @inventory/group_vars/examples/manage-safe.yml
ansible-playbook -i inventory/local.yml playbooks/manage-system.yml -K -e @inventory/group_vars/examples/manage-full.yml
```
