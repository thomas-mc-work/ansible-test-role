#!/usr/bin/env sh
# Isolated testing an ansible role.
#
# Further reading: Ansible Configuration - Common Options
# https://docs.ansible.com/ansible/2.4/config.html
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable

fn_print_usage () {
    cat <<HELP
Wrapper script for ansible-playbook to apply single role.

Usage: $(basename $0) <role-path> [ansible-playbook options]

Examples:
  $(basename $0) /path/to/my_role
  $(basename $0) /path/to/roles/apache-webserver -i 'custom_host,' -vv --check
HELP
}

## prepare cli parameters

if [ $# -lt 1 ]; then
    fn_print_usage
    exit 1
fi

check_idempotence=0

while true; do
	case $1 in
		-h|-\?|--help)
			fn_print_usage
            exit
			break;
			;;
		-i|--verify-idempotence)
			check_idempotence=1
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


echo "Testing role '${role_path}' ..."

# verify readability of the role
if [ ! -r "$role_path" ]; then
    echo "Failed to read the role: ${role_path}"
    exit 2
fi

ansible-role.sh "$role_path"
sc=$?

# optional: verify idempotency
if [ $check_idempotence -eq 1 ]; then
    ansible_output=$(mktemp)
    ansible-role.sh "$role_path" | tee "$ansible_output"
    if ! grep -qE "ok=.+changed=0.+unreachable=.+failed=0" $ansible_output; then
        echo "idempotence check failed!"
        sc=20
    fi
    rm -f "$ansible_output"
fi

ansible-role.sh -c "$role_path"

exit $sc