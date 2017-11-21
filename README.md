# ansible-test-role

A tool to run and verify a single ansible role in a temporary virtual machine to verify it's correctness.

Default vagrant image is Debian 8 64 bit (`debian/jessie64`).

### What is it doing exactly?

1. Prepare and start a temporary vagrant machine
2. Create a temporary ansible inventory based on the vagrant machine data
3. Run `ansible-playbook` with a temporary playbook only containing the role passed to the script as a parameter
4. tear down the vagrant machine and remove all temporary files

## Requirements

- [ansible](http://docs.ansible.com/ansible/latest/intro_installation.html)
- [vagrant](https://www.vagrantup.com/downloads.html)
- any [compatible virtual machine environment](https://www.vagrantup.com/docs/providers/), e.g.
    * `virtualbox`
    * `libvirt`

## Setup

    sudo curl -O "/usr/local/bin/ansible-test-role" "https://github.com/..."
    sudo chmod +x "/usr/local/bin/ansible-test-role"

You could also replace the target to your personal bin folder (`$HOME/bin`).

## Usage

Simply `cd` into your ansible folder and then run:

    ansible-test-role <role-name> [ansible-playbook options]

`ansible-playbook options`: These can be [valid `ansible-playbook` options](http://docs.ansible.com/ansible/latest/ansible-playbook.html) which wil be passed through.

### Allowed environment variables

You can define several environment variables which are used by [vagrant](https://www.vagrantup.com/docs/other/environmental-variables.html) or [ansible](http://docs.ansible.com/ansible/latest/config.html) like these:

- `VAGRANT_DEFAULT_PROVIDER`: The latest version of vagrant (2.0 as of 2017-10-27) isn't able to work with virtualbox version ≥ 5.2 – so you can easily switch to e.g. `libvirt` herewith

### Forbidden environment variables

These are defined in the script and thus overridden:

- `ANSIBLE_ROLES_PATH`
- `ANSIBLE_RETRY_FILES_ENABLED`
- `ANSIBLE_INVENTORY`
- `VAGRANT_CWD`

## Alternatives

- [Molecule](https://molecule.readthedocs.io/en/latest/): It seems to be a very more profound solution. One big drawback is the big footprint of configuration files that it creates in your project (and thus in your SCM).
- [RoleSpec](https://github.com/nickjj/rolespec): focuses on Travis-CI integration
- [ansible-test](https://github.com/nylas/ansible-test): (didn't work on my machine: Xubuntu 16.04.3)

## Thanks to

… [Konstantin Suvorov aka @berlic](https://github.com/berlic) for [this inspiration](https://stackoverflow.com/a/38419466/2854723)
