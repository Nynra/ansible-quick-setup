# ansible-sec-tools

Ansible roles to quickly set up a pentest host. Mostly copied from [Hacked by a girl](https://github.com/hackedbyagirl/offensive-kali-ansible/tree/main)

## Kali or Linux Host

The following is required to be on the system before running this ansible playbook

- ansible

This can be installed using the following command

`sudo apt-get install ansible`

or using python

```bash
python3 -m pip install ansible
```

## Roles

To decide which roles you would like to do, edit the `playbook.yml` file.

Ex: If you are performing an internal penetration test, the site file should look like this:

```yaml
# Main Playbook
---
- hosts: all
  roles:
    - common 
    - internal
```

Vice versa for external, or even both! They can be integrated to include all tools for each portion of a test.

### Local Execution

 After ansible is installed on your local kali host, clone this repo and run ansible playbook.

```bash
ansible-playbook -i ansible/<platform-file> playbook.yml
```

### Set inventory

This playbook is intented to automate a defaut offensive environment on kali hosts. In order to use this playbook efficently, it should be run against an inventory of kali hosts. This can be done by creating an inventory of hosts.

To configure the hosts inventory, open and edit the hosts.ini file to include the hosts in the following manner. This is just an example.

```yml
parrot:
  hosts:
    localhost:
      ansible_connection: local
      ansible_user: parrot

```
