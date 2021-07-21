# Ansible

- Create inventory file in `./inventory` with at least one server in the `[server]` group
- Change variables in `./inventory/group-vars/server.yml` as required
- Run `ansible-playbook -i ./inventory playbooks/setup-server.yml -u root`
- This will install madoc and dependencies on the chosen server and start madoc

## Roadmap

- Splitting internal databases in docker-compose files
- New database-less playbook
- Postgres set up for shared-database (can point to external)
