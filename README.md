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

To decide which roles you would like to do, edit the `site.yml` file.

Ex: If you are performing an external penetration test, the site file should look like this:

```yaml
# Main Playbook
---
- hosts: kali
  roles:
    - common 
    - external
```

Vice versa for internal, or even both! They can be integrated to include all tools for each portion of a test.

### Local Execution

 After ansible is installed on your local kali host, clone this repo and run ansible playbook.

```bash
ansible-playbook -i ansible/local.ini site.yml -K
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

### Configure Hosts in site.yml

This playbook sets up ansible to be ran on a local host. To change that to, edit the `site.yml` file and change

`hosts: localhost` to `hosts: kali`

### Setting a Remote User

By default, ansible connects to all remote devices with the username you are using on the control node. If that username does not exist on the remote device, you will need to set a different username for the connection in the playbook. By default, this playbook will have the username set to `kali` in the inventory file `ansible/hosts.ini`

## Execution

Download, edit, and run!

```bash
# clone repo, move to directory, execute playbook 
git clone https://github.com/hackedbyagirl/offensive-kali-ansible.git
cd offensive-kali-ansible

# Edit inventory file with host and configurations -- save 
vim ansible/hosts.ini

# Edit global variabsl 
vim group_vars/kali/main
<zsh_user> - line 3
<group> - line 92
<user> - line 93

# Edit site.yml to ensure it's being deployed on kali hosts
vim site.yml

# Deploy playbook
ansible-playbook -i ansible/hosts.ini site.yml --ask-become-pass
```
