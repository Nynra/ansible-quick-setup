# ansible-sec-tools

Ansible resource for quickly setting up hosts.

# Ensure ansible is set up

Using `pipx`

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install ansible
# Running ansible-galaxy collection install -r or ansible-galaxy role install -r will only install collections, or roles respectively.
ansible-galaxy install -r requirements.yml
```
