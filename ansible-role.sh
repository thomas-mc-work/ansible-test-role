#!/usr/bin/env sh
# Isolated execution of an ansible role.
#
# Further reading: Ansible Configuration - Common Options
# https://docs.ansible.com/ansible/2.4/config.html
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable


vagrant_box="debian/jessie64"
data_base_dir="/var/lib/ansible-role"

# #####

fn_print_usage () {
    cat <<HELP
Wrapper script for ansible-playbook to apply single role.

Usage: $(basename $0) <role-path> [ansible-playbook options]

Examples:
  $(basename $0) /path/to/my_role
  $(basename $0) /path/to/roles/apache-webserver -i 'custom_host,' -vv --check
HELP
}

# ########

fn_prepare_machine () {
    mkdir -p "$data_dir"

    cat > "${VAGRANT_CWD}/Vagrantfile" <<END
Vagrant.configure(2) do |config|
  config.vm.box = "$vagrant_box"
  config.vm.network "private_network", type: "dhcp"
  config.vm.define "ansible-role"
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
        echo "failed to ssh ping to the virtual machine (vagrant ssh)"
        vagrant status
        exit 11
    fi

    machine_ip=$(vagrant ssh-config | grep -i HostName | cut -d' ' -f4)
    machine_ssh_port=$(vagrant ssh-config | grep -i Port | cut -d' ' -f4)
    machine_private_key=$(vagrant ssh-config | grep -i IdentityFile | cut -d' ' -f4)

    # create temporary ansible inventory file
    cat > "$ansible_inventory" <<END
[vagrant]
$machine_ip ansible_port=${machine_ssh_port} ansible_user=vagrant ansible_ssh_private_key_file=${machine_private_key}
END

    # create temporary playbook.yml
    
    cat > "$ansible_playbook" <<END
---
- hosts: ${machine_ip}
  become: yes

  roles:
    - ${role_name}
END
}

# ########

fn_execute_ansible_playbook () {
    echo "# running ansible-playbook:"
    echo "    "ansible-playbook --ssh-extra-args \"-o UserKnownHostsFile=/dev/null\" --ssh-extra-args \"-o StrictHostKeyChecking=no\" \
      -i \"$ansible_inventory\" \"$ansible_playbook\"

    ansible-playbook --ssh-extra-args "-o UserKnownHostsFile=/dev/null" --ssh-extra-args "-o StrictHostKeyChecking=no" \
      -i "$ansible_inventory" "$ansible_playbook"
}

# ########

fn_clean_up () {
    vagrant destroy -f
    vagrant_sc=$?
    if [ $vagrant_sc -ne 0 ]; then
        echo "failed to remove virtual machine: ${vagrant_sc}"
        echo "    $ vagrant destroy -f"
        echo "    $ rm -rfv '$data_dir'"
        exit 30
    fi

    rm -rf "$data_dir"
}

mkdir -p "$data_base_dir"

## prepare cli parameters

if [ $# -lt 1 ]; then
    fn_print_usage
    exit 1
fi

clean_up=0
remove_on_success=0
remove_after=0

while true; do
	case $1 in
		-h|-\?|--help)
			fn_print_usage
            exit
			;;
		-s|--remove-on-success)
			remove_on_success=1
			;;
		-r|--remove_after)
			remove_after=1
			;;
		-c|--clean-up)
		    clean_up=1
		    ;;
		--)
			shift
            role_path="$(realpath $1)"
			break
			;;
		-*)
			printf "CLI error: Unmatched argument: '%s'\n" $1
			fn_print_usage
			exit 1
			;;
		*)
			role_path="$(realpath $1)"
			break
	esac

	shift
done


# verify readability of the role
if [ ! -r "$role_path" ]; then
    echo "Failed to read the role: ${role_path}"
    exit 2
fi

role_name=$(basename "$role_path")
role_hash=$(printf "$role_path" | md5sum | cut -f 1 -d " ")
data_dir="${data_base_dir}/${role_hash}"
ansible_inventory="${data_dir}/inventory.ini"
ansible_playbook="${data_dir}/playbook.yml"

# define vagrant working dir
export VAGRANT_CWD=$data_dir
# define the ansible roles path
export ANSIBLE_ROLES_PATH=$(dirname "$role_path")

if [ $clean_up -eq 1 ]; then
    fn_clean_up
    exit
fi

echo "Trying to apply role '${role_name}' ..."

if [ ! -d "$data_dir" ]; then
    fn_prepare_machine
else
    vagrant up
fi

fn_execute_ansible_playbook
sc=$?

if [ $remove_on_success -eq 1 -a $sc -eq 0 ] || [ $remove_after -eq 1 ]; then
    fn_clean_up
fi

exit $sc