# ansible-role + ansible-test-role

**ansible-role**: Run an ansible role in an isolated disposable environment (a temporary vagrant virtual machine)

**ansible-test-role**: Test a single ansible role in a temporary virtual machine to verify it's correctness.

Default vagrant image is Debian 8 64 bit (`debian/jessie64`).

### What is it doing exactly?

1. Reuse or prepare a temporary vagrant machine and start it
2. Create a temporary ansible inventory based on the vagrant machine data
3. Run `ansible-playbook` with a temporary playbook only containing the role passed to the script as a parameter
4. Optional: Tear down the vagrant machine and remove all temporary files

## Requirements

- [ansible](http://docs.ansible.com/ansible/latest/intro_installation.html)
- [vagrant](https://www.vagrantup.com/downloads.html)
- any [compatible virtual machine environment](https://www.vagrantup.com/docs/providers/), e.g.
    * `virtualbox`
    * `libvirt`

## Setup

    sudo curl -Lo "/usr/local/bin/ansible-role" "https://raw.githubusercontent.com/thomas-mc-work/ansible-test-role/master/ansible-role.sh"
    sudo curl -Lo "/usr/local/bin/ansible-test-role" "https://raw.githubusercontent.com/thomas-mc-work/ansible-test-role/master/ansible-test-role.sh"
    sudo chmod +x "/usr/local/bin/ansible-role" "/usr/local/bin/ansible-test-role"

The target folder `/usr/local/bin` could also be replaced by your personal bin folder (`$HOME/bin`).

## Usage

**ansible-role:**

    ansible-role <role-path> [ansible-playbook options]

**ansible-test-role:**
    
    ansible-test-role <role-path> [ansible-playbook options]

`ansible-playbook options`: These can be [valid `ansible-playbook` options](http://docs.ansible.com/ansible/latest/ansible-playbook.html) which wil be passed through.

### Allowed environment variables

You can define several environment variables which are used by [vagrant](https://www.vagrantup.com/docs/other/environmental-variables.html) or [ansible](http://docs.ansible.com/ansible/latest/config.html) like these:

- `VAGRANT_DEFAULT_PROVIDER`: The latest version of vagrant (2.0 as of 2017-10-27) isn't able to work with virtualbox version ≥ 5.2 – so you can easily switch to e.g. `libvirt` herewith

### Forbidden environment variables

These are defined in the script and thus overridden:

- `ANSIBLE_ROLES_PATH`
- `ANSIBLE_INVENTORY`
- `VAGRANT_CWD`

## Alternatives

- [Molecule](https://molecule.readthedocs.io/en/latest/): It seems to be a very more profound solution. One big drawback is the big footprint of configuration files that it creates in your project (and thus in your SCM).
- [RoleSpec](https://github.com/nickjj/rolespec): focuses on Travis-CI integration
- [ansible-test](https://github.com/nylas/ansible-test): (didn't work on my machine: Xubuntu 16.04.3)

## Thanks to

… [Konstantin Suvorov aka @berlic](https://github.com/berlic) for [this inspiration](https://stackoverflow.com/a/38419466/2854723)
