# ansible-sec-tools

Ansible roles to quickly set up a pentest host. Mostly copied from [Hacked by a girl](https://github.com/hackedbyagirl/offensive-kali-ansible/tree/main).

## Kali or Linux Host

The following is required to be on the system before running this ansible playbook

- ansible

This can be installed using the following command

`sudo apt-get install ansible`

or using python

```bash
python3 -m pip install ansible
```

## Collections and Roles

The playbook consumes the `structam.sec_tools` collection. The setup script
installs it and its package-installer dependency from the Git repositories in
`requirements.yml`.

The common role is enabled by default. To also install internal testing tools,
uncomment the `structam.sec_tools.internal` role in `playbook.yml`.

Ex: If you are performing an internal penetration test, the site file should look like this:

```yaml
# Main Playbook
---
- hosts: all
  roles:
    - role: structam.sec_tools.common
    - role: structam.sec_tools.internal
```

Vice versa for external, or even both! They can be integrated to include all tools for each portion of a test.

### Local Execution

After cloning this repository, run the setup script from its root directory.

```bash
./setup.bash
```

The script will:

- create or reuse a local `.venv`
- install Ansible if needed
- install the required collections from `requirements.yml`
- let you choose an inventory from `inventory/`
- show a final summary before running the playbook
- optionally remove the venv after the run

Available inventory files include:

- `desktop.yml` for desktop hosts
- `htb.yml` for Hack The Box-style targets
- `trixie.yml` for Debian Trixie hosts

To run Ansible directly after installing the requirements:

```bash
ansible-playbook -i inventory/desktop.yml playbook.yml -K
```

You can also skip the extra confirmation prompts in non-interactive use:

```bash
./setup.bash --auto
./setup.bash --auto --inventory inventory/desktop.yml
```

Or pass extra arguments through to `ansible-playbook`:

```bash
./setup.bash -- --tags common
./setup.bash --inventory inventory/desktop.yml -- --check
```

### Set inventory

This playbook is intented to automate a defaut offensive environment on kali hosts. In order to use this playbook efficently, it should be run against an inventory of kali hosts. This can be done by creating an inventory of hosts.

To configure a host, edit the appropriate inventory file. The group name must
match the corresponding file under `inventory/group_vars/`.

```yml
parrot:
  hosts:
    localhost:
      ansible_connection: local
      ansible_user: parrot

```
