General setup
==============

The `structam.general_server_management.env` role manages Bash, Tmux, and
Neovim configuration for a target user on Debian-family systems. It is not
responsible for host hardening.

Target User
-----------

Set `target_user` and `target_user_home` when configuring a user other than the
Ansible connection user. Set `target_user_become: true` when those files must be
managed through privilege escalation.

Safe Uninstall
--------------

Uninstall removes only configuration blocks and files created by this role. It
does not delete the user's complete `.bashrc`, `.profile`, `.tmux.conf`, or
Neovim configuration. Neovim package removal is opt-in with
`nvim_remove_package: true`.

The Ubuntu Neovim PPA is disabled by default. Enable it explicitly with
`nvim_use_ppa: true` on Ubuntu hosts that require newer Neovim builds.
