#!/bin/bash
#
# Set up (or reuse) a local Python venv with Ansible, pick an inventory
# file, confirm, and run the playbook.
#
# Usage:
#   ./run-playbook.sh [-- extra ansible-playbook args, e.g. --tags foo]
#
set -euo pipefail

VENV_DIR=".venv"
INVENTORY_DIR="inventory"
PLAYBOOK="playbook.yml"

# --- Sanity checks ---------------------------------------------------------
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required but not found." >&2; exit 1; }

if [[ ! -f "$PLAYBOOK" ]]; then
    echo "Error: $PLAYBOOK not found in $(pwd)." >&2
    exit 1
fi

if [[ ! -d "$INVENTORY_DIR" ]] || [[ -z "$(ls -A "$INVENTORY_DIR" 2>/dev/null)" ]]; then
    echo "Error: no inventory files found in $INVENTORY_DIR/." >&2
    exit 1
fi

# --- Virtual environment -----------------------------------------------------
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Creating virtual environment in $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Installing ansible..."
    pip install --upgrade pip
    pip install ansible
fi

# --- Choose inventory --------------------------------------------------------
echo "Select an inventory file (or q to quit):"
PS3="Enter a number: "
select inventory_file in "$INVENTORY_DIR"/*; do
    if [[ -n "${inventory_file:-}" ]]; then
        break
    fi
    if [[ "$REPLY" =~ ^[Qq]$ ]]; then
        echo "Quitting."
        exit 1
    fi
    echo "Invalid selection, try again."
done

# --- Confirm and run ----------------------------------------------------------
echo
echo "Inventory: $inventory_file"
echo "Command:   ansible-playbook -i $inventory_file $PLAYBOOK -K $*"
echo

read -rp "Proceed? (y/n/q) " confirm
case "$confirm" in
    [Yy]*)
        ansible-playbook -i "$inventory_file" "$PLAYBOOK" -K "$@"
        ;;
    [Qq]*)
        echo "Quitting."
        exit 1
        ;;
    *)
        echo "Aborting."
        exit 1
        ;;
esac

# --- Cleanup -------------------------------------------------------------------
deactivate

# Ask the user if they want to remove the virtual environment
read -rp "Remove virtual environment $VENV_DIR? (y/n) " remove_venv
if [[ "$remove_venv" =~ ^[Yy]$ ]]; then
    rm -rf "$VENV_DIR"
    echo "Virtual environment removed."
else
    echo "Virtual environment retained in $VENV_DIR."
fi