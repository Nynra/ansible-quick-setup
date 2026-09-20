# Ansible Package Installer

The `structam.ansible_package_installer.installers` role installs APT packages,
Python packages, Git repositories, standalone downloads (e.g. GitHub release
binaries/archives), and command-line tool symlinks on Debian-family systems
such as Debian, Ubuntu, and Parrot OS.

## Use As A Dependency

Install the collection from `requirements.yml`:

```yaml
collections:
  - name: structam.ansible_package_installer
    type: git
    source: https://gitlab.eaglediksix.nl/ansible/collections/ansible-package-installer.git
```

Call the role by its fully qualified name from another role or playbook:

```yaml
- name: Install shared tools
  ansible.builtin.include_role:
    name: structam.ansible_package_installer.installers
  vars:
    installer_apt_packages:
      - git
      - ripgrep
```

The role does nothing when all input lists are empty.

## Common Variables

```yaml
installer_apt_packages: []
installer_apt_cleanup: false
installer_apt_install_recommends: true

installer_pip_packages: []
installer_pip_upgrade: false
installer_pip_virtualenv: ""
installer_pip_virtualenv_command: "python3 -m venv"
installer_pip_executable: pip3
installer_pip_become: false
installer_pip_virtualenvs: []

installer_git_repos: []
# Each repository may also set python_install to setup or requirements.
installer_git_force: false
installer_git_python_script_symlinks: []
installer_git_python_file_symlinks: []
installer_git_symlinks: []
installer_git_symlink_become: true

installer_download_files: []
installer_download_become: true
installer_download_force: false
installer_download_archives: []
installer_download_symlinks: []
installer_download_symlink_become: true
```

Git symlink `src` and `dest` values should be absolute paths. Python tool
symlinks resolve scripts from `<path>/venv/bin` and create aliases in
`/usr/local/bin`.

Use `installer_git_python_script_symlinks` when the Python package installs a
console script into its venv:

```yaml
installer_git_python_script_symlinks:
  - path: /opt/tools/network/certipy
    script: certipy
    alias: certipy
```

Use `installer_git_python_file_symlinks` for scripts that live directly in a
Git repository rather than being installed as console scripts. Each entry
requires the repository root, a script path relative to that root, and an
alias. The generated launcher uses the repository's `venv/bin/python`:

```yaml
installer_git_python_file_symlinks:
  - path: /opt/tools/example-tool
    script: src/example.py
    alias: example-tool
```

For system-wide Python tools, use a dedicated virtual environment rather than
installing into the distribution-managed Python environment:

```yaml
installer_pip_packages:
  - poetry
installer_pip_virtualenv: /opt/tools-venv
installer_pip_become: true
```

To install separate sets of packages into multiple virtual environments, use
`installer_pip_virtualenvs`. Each entry requires a `path` and `packages`; the
other fields override the role-wide defaults for that environment:

```yaml
installer_pip_virtualenvs:
  - path: /opt/builder-venv
    packages:
      - build
      - wheel
    upgrade: true
  - path: /opt/cracking-venv
    packages:
      - impacket
      - hashid
```

The existing `installer_pip_packages` and `installer_pip_virtualenv` variables
remain supported for a single package set.

Repository entries require `path`, `dir_name`, and `repo`:

```yaml
installer_git_repos:
  - path: /opt/recon-tools
    dir_name: example-tool
    repo: https://github.com/example/example-tool.git
    branch: main
    python_install: setup
```

Set `python_install: setup` for a repository containing `setup.py` or
`pyproject.toml`, or set `python_install: requirements` for a repository whose
Python dependencies are listed in `requirements.txt`:

```yaml
installer_git_repos:
  - path: /opt/tools/network
    dir_name: certipy
    repo: https://github.com/ly4k/Certipy.git
    python_install: setup
  - path: /opt/tools/osint
    dir_name: knockpy
    repo: https://github.com/guelfoweb/knock.git
    python_install: requirements
```

For these entries the role clones each repository to
`<path>/<dir_name>` and creates its virtual environment at
`<path>/<dir_name>/venv`.

Downloads support two kinds of items: standalone files, such as a single
GitHub release binary, and archives that get extracted on the target after
download:

```yaml
installer_download_files:
  - path: /opt/tools
    dest_name: tool
    url: https://github.com/example/example-tool/releases/download/v1.0/tool-linux-amd64
    mode: "0755"
    checksum: "sha256:abcdef..."

installer_download_archives:
  - path: /opt/tools/example-tool
    url: https://github.com/example/example-tool/releases/download/v1.0/tool-linux-amd64.tar.gz
    creates: /opt/tools/example-tool/tool

installer_download_symlinks:
  - src: /opt/tools/example-tool/tool
    dest: /usr/local/bin/tool
```

`installer_download_files` entries require `path`, `dest_name`, and `url`, and
use `ansible.builtin.get_url` (optionally verifying a `checksum`).
`installer_download_archives` entries require `path` and `url`, and are
downloaded and extracted on the target with `ansible.builtin.unarchive`;
set `creates` to skip re-extracting when the tool is already present.

The role validates all public variables with `meta/argument_specs.yml` before
installing anything.
