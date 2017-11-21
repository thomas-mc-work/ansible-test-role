#!/usr/bin/env bash
# Test an ansible role solely.
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable

if [ $# -lt 1 ]; then
  cat <<HELP
Wrapper script for ansible-playbook to apply single role.

Usage: $0 <role-name> [ansible-playbook options]

Examples:
  $0 my_role
  $0 apache-webserver -i 'custom_host,' -vv --check
HELP
  exit
fi

role_path=$1
role_name=$(basename "$role_path")
shift

echo "Trying to apply role '${role_name}' ..."

# verify readability of the role
if [ ! -r "$role_path" ]; then
    echo "Failed to read the role: ${role_path}"
    exit 4
fi

# define the ansible roles path
export ANSIBLE_ROLES_PATH=$(dirname $(realpath "$role_path"))

# prepare vagrant environment
export VAGRANT_CWD=$(mktemp -d)

cat > "${VAGRANT_CWD}/Vagrantfile" <<END
Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessie64"
  config.vm.network "private_network", type: "dhcp"
  config.vm.define "ansible-test-role"
end
END

vagrant box update

# start virtual machine
vagrant up
sc=$?
if [ $sc -ne 0 ]; then
    echo "failed to bring up virtual machine: ${sc}"
    exit 1
fi

if ! vagrant ssh -c exit 2> /dev/null; then
    echo "failed to get ssh ping to the machine (vagrant ssh)"
    vagrant status
    exit 2
fi

machine_ip=$(vagrant ssh-config | grep -i HostName | cut -d' ' -f4)
machine_ssh_port=$(vagrant ssh-config | grep -i Port | cut -d' ' -f4)
machine_private_key=$(vagrant ssh-config | grep -i IdentityFile | cut -d' ' -f4)
echo "machine has booted: ${machine_ip}"

export ANSIBLE_RETRY_FILES_ENABLED="False"

# create temporary ansible inventory file
ansible_inventory=$(mktemp)
cat > "$ansible_inventory" <<END
[vagrant]
$machine_ip ansible_port=${machine_ssh_port} ansible_user=vagrant ansible_ssh_private_key_file=${machine_private_key}
END

# create temporary playbook.yml
ansible_playbook=$(mktemp)
cat > "$ansible_playbook" <<END
---
- hosts: ${machine_ip}
  become: yes

  roles:
    - ${role_name}
END

# execute the virtual playbook
ansible-playbook --ssh-extra-args "-o UserKnownHostsFile=/dev/null" --ssh-extra-args "-o StrictHostKeyChecking=no" \
  -i "$ansible_inventory" "$ansible_playbook"

# clean up
rm -f "$ansible_inventory" "$ansible_playbook"

vagrant destroy -f
sc=$?
if [ $sc -ne 0 ]; then
    echo "failed to remove virtual machine: ${sc}"
    echo "    $ vagrant destroy -f"
    echo "    $ rm -rfv '$VAGRANT_CWD'"
    exit 3
fi

rm -rf "$VAGRANT_CWD"