#!/usr/bin/env bash
#
# Set up (or reuse) a local Python venv with Ansible, pick an inventory
# file, confirm, and run the playbook.
#
# Usage:
#   ./setup.bash [--inventory path.yml] [--no-confirm] [-- extra ansible-playbook args]
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VENV_DIR="${VENV_DIR:-$SCRIPT_DIR/.venv}"
INVENTORY_DIR="${INVENTORY_DIR:-$SCRIPT_DIR/inventory}"
PLAYBOOK="${PLAYBOOK:-$SCRIPT_DIR/playbook.yml}"
REQUIREMENTS="${REQUIREMENTS:-$SCRIPT_DIR/requirements.yml}"
CONFIRM_DEFAULT=true
INVENTORY_OVERRIDE=""
ANSIBLE_ARGS=()
PROCEED=true
REMOVE_VENV=false
AUTO_MODE=false
LOCAL_COLLECTIONS_ROOT="$SCRIPT_DIR/collections"
LOCAL_STRUCTAM_COLLECTIONS="$LOCAL_COLLECTIONS_ROOT/ansible_collections/structam"

usage() {
    cat <<'EOF'
Usage: ./setup.bash [--inventory|-i path.yml] [--no-confirm|-n] [--auto|-a] [-- extra ansible-playbook args]

Examples:
  ./setup.bash
  ./setup.bash -i inventory/desktop.yml
  ./setup.bash -n -- --tags common
  ./setup.bash -a -i inventory/desktop.yml
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--inventory)
            [[ $# -ge 2 ]] || { echo "Error: --inventory requires a path." >&2; exit 1; }
            INVENTORY_OVERRIDE="$2"
            shift 2
            ;;
        -n|--no-confirm)
            CONFIRM_DEFAULT=false
            shift
            ;;
        -a|--auto)
            AUTO_MODE=true
            CONFIRM_DEFAULT=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            ANSIBLE_ARGS=("$@")
            break
            ;;
        *)
            ANSIBLE_ARGS=("$@")
            break
            ;;
    esac
done

# --- Sanity checks ---------------------------------------------------------
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required but not found." >&2; exit 1; }

if [[ ! -f "$PLAYBOOK" ]]; then
    echo "Error: playbook not found at $PLAYBOOK" >&2
    exit 1
fi

if [[ ! -f "$REQUIREMENTS" ]]; then
    echo "Error: requirements file not found at $REQUIREMENTS" >&2
    exit 1
fi

if [[ ! -d "$INVENTORY_DIR" ]]; then
    echo "Error: inventory directory not found at $INVENTORY_DIR" >&2
    exit 1
fi

mapfile -t inventory_files < <(
    find "$INVENTORY_DIR" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) -print | sort
)

if [[ "${#inventory_files[@]}" -eq 0 ]]; then
    echo "Error: no YAML inventory files found in $INVENTORY_DIR/" >&2
    exit 1
fi

inventory_labels=()
for inventory_file_path in "${inventory_files[@]}"; do
    inventory_labels+=("$(basename "$inventory_file_path")")
done

# --- Gather all user input up front ------------------------------------------
if [[ -n "$INVENTORY_OVERRIDE" ]]; then
    inventory_file="$INVENTORY_OVERRIDE"
    if [[ ! -f "$inventory_file" ]]; then
        echo "Error: inventory file not found at $inventory_file" >&2
        exit 1
    fi
else
    if [[ "${#inventory_files[@]}" -eq 1 ]]; then
        inventory_file="${inventory_files[0]}"
    else
        echo "Select an inventory file (or q to quit):"
        PS3="Enter a number: "
        select inventory_label in "${inventory_labels[@]}"; do
            if [[ -n "${inventory_label:-}" ]]; then
                inventory_file="${inventory_files[$((REPLY - 1))]}"
                break
            fi
            if [[ "$REPLY" =~ ^[Qq]$ ]]; then
                echo "Quitting."
                exit 1
            fi
            echo "Invalid selection, try again."
        done
    fi
fi

if [[ "$CONFIRM_DEFAULT" == true ]]; then
    read -rp "Run playbook with $inventory_file? [y/N/q] " proceed_choice
    case "$proceed_choice" in
        [Yy]*)
            PROCEED=true
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

    read -rp "Delete venv after run? [y/N] " remove_venv
    if [[ "$remove_venv" =~ ^[Yy]$ ]]; then
        REMOVE_VENV=true
    fi
elif [[ "$AUTO_MODE" == true ]]; then
    PROCEED=true
    REMOVE_VENV=false
fi

# --- Final summary -----------------------------------------------------------
command_string=(ansible-playbook -i "$inventory_file" "$PLAYBOOK" -K)
if [[ "${#ANSIBLE_ARGS[@]}" -gt 0 ]]; then
    command_string+=("${ANSIBLE_ARGS[@]}")
fi

echo
printf 'Inventory: %s\n' "$inventory_file"
printf 'Playbook: %s\n' "$PLAYBOOK"
printf 'Command: %s\n' "${command_string[*]}"
if [[ "$REMOVE_VENV" == true ]]; then
    printf 'Cleanup: delete venv after run\n'
else
    printf 'Cleanup: keep venv after run\n'
fi

echo
if [[ "$CONFIRM_DEFAULT" == true ]]; then
    read -rp "Looks good? [y/N/q] " final_choice
    case "$final_choice" in
        [Yy]*)
            PROCEED=true
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
elif [[ "$AUTO_MODE" == true ]]; then
    PROCEED=true
fi

# --- Virtual environment -----------------------------------------------------
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Creating virtual environment in $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
trap 'deactivate >/dev/null 2>&1 || true' EXIT

if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Installing Ansible into the virtual environment..."
    python -m pip install --upgrade pip
    python -m pip install ansible
fi

echo "Installing required Ansible collections..."
collection_names=()
while IFS= read -r collection_name; do
    [[ -n "$collection_name" ]] && collection_names+=("$collection_name")
done < <(grep -E '^[[:space:]]*-[[:space:]]*name:' "$REQUIREMENTS" | sed -E 's/^[[:space:]]*-[[:space:]]*name:[[:space:]]*//')

if [[ ${#collection_names[@]} -eq 0 ]]; then
    echo "No collection entries found in $REQUIREMENTS."
else
    for collection_name in "${collection_names[@]}"; do
        echo "Installing collection: $collection_name"
        if ansible-galaxy collection install --upgrade "$collection_name"; then
            continue
        fi

        if [[ "$collection_name" == structam.* && -d "$LOCAL_STRUCTAM_COLLECTIONS" ]]; then
            echo "Warning: unable to install $collection_name. Falling back to the bundled local collections in $LOCAL_COLLECTIONS_ROOT."
            export ANSIBLE_COLLECTIONS_PATH="$LOCAL_COLLECTIONS_ROOT"
            export ANSIBLE_COLLECTIONS_PATHS="$LOCAL_COLLECTIONS_ROOT"
            continue
        fi

        echo "Warning: collection $collection_name could not be installed and no local fallback was found. Continuing without it."
    done
fi

# --- Run ----------------------------------------------------------
if [[ "$PROCEED" != true ]]; then
    echo "Aborting."
    exit 1
fi

"${command_string[@]}"

# --- Cleanup -------------------------------------------------------------------
if [[ "$REMOVE_VENV" == true ]]; then
    rm -rf "$VENV_DIR"
    echo "Virtual environment removed."
else
    echo "Virtual environment retained in $VENV_DIR."
fi