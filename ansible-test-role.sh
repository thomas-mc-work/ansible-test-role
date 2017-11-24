#!/usr/bin/env sh
# Test an ansible role isolated.
#
# Further reading: Ansible Configuration - Common Options
# https://docs.ansible.com/ansible/2.4/config.html
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable


vagrant_box="debian/jessie64"


fn_print_usage () {
    cat <<HELP
Wrapper script for ansible-playbook to apply single role.

Usage: $(basename $0) <role-name> [ansible-playbook options]

Examples:
  $(basename $0) my_role
  $(basename $0) apache-webserver -i 'custom_host,' -vv --check
HELP
}

# ###

fn_prepare_machine () {
    export VAGRANT_CWD=$(mktemp -d)

    cat > "${VAGRANT_CWD}/Vagrantfile" <<END
Vagrant.configure(2) do |config|
  config.vm.box = "$vagrant_box"
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
        exit 10
    fi

    if ! vagrant ssh -c exit 2> /dev/null; then
        echo "failed to get ssh ping to the machine (vagrant ssh)"
        vagrant status
        exit 11
    fi

    machine_ip=$(vagrant ssh-config | grep -i HostName | cut -d' ' -f4)
    machine_ssh_port=$(vagrant ssh-config | grep -i Port | cut -d' ' -f4)
    machine_private_key=$(vagrant ssh-config | grep -i IdentityFile | cut -d' ' -f4)
    echo "machine has booted: ${machine_ip}"

    # define the ansible roles path
    export ANSIBLE_ROLES_PATH=$(dirname $(realpath "$role_path"))
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
}

# ###

fn_execute_ansible_playbook () {
    ansible-playbook --ssh-extra-args "-o UserKnownHostsFile=/dev/null" --ssh-extra-args "-o StrictHostKeyChecking=no" \
      -i "$ansible_inventory" "$ansible_playbook"
}

# ###

fn_clean_up () {
    rm -f "$ansible_inventory" "$ansible_playbook"
    [ $ansible_output ] && rm -f "$ansible_output"

    vagrant destroy -f
    vagrant_sc=$?
    if [ $vagrant_sc -ne 0 ]; then
        echo "failed to remove virtual machine: ${vagrant_sc}"
        echo "    $ vagrant destroy -f"
        echo "    $ rm -rfv '$VAGRANT_CWD'"
        exit 30
    fi

    rm -rf "$VAGRANT_CWD"
}

## prepare cli parameters

if [ $# -lt 1 ]; then
    fn_print_usage
    exit 1
fi

action='show_help'
check_idempotence=0

while true; do
	case $1 in
		-h|-\?|--help)
			action='show_help'
			break;
			;;
		-i|--verify-idempotence)
			check_idempotence=1
			;;
		--)
			shift
            role_path="$1"
            action='operate'
			break
			;;
		-*)
			printf "CLI error: Unmatched argument: '%s'\n" $1
			fn_print_usage
			exit 1
			;;
		*)
			role_path="$1"
			action='operate'
			break
	esac

	shift
done

if [ "$action" = 'show_help' ]; then
	fn_print_usage
    exit
fi

role_name=$(basename "$role_path")

echo "Trying to apply role '${role_name}' ..."

# verify readability of the role
if [ ! -r "$role_path" ]; then
    echo "Failed to read the role: ${role_path}"
    exit 2
fi

## actual start of the program

fn_prepare_machine

fn_execute_ansible_playbook
sc=$?

# optional: verify idempotency
if [ $check_idempotence = '1' ]; then
    ansible_output=$(mktemp)
    fn_execute_ansible_playbook | tee "$ansible_output"
    if ! grep -qE "ok=.+changed=0.+unreachable=.+failed=0" $ansible_output; then
        echo "idempotence check failed!"
        sc=20
    fi
else
    # preemptive initialization to avoid errors due to an uninitialised variable
    ansible_output=
fi

## clean up
fn_clean_up

exit $sc