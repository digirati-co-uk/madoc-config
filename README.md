# Madoc config


## Updating docker-compose definitions

There are the following docker-compose files that need to be updated:

- `./docker-compose.yaml` - completely standalone
- `./local/docker-compose.yaml` - local with local volumes
- `./ec2/docker-compose.yaml` - for working on a linux EC2
- `./ansbile/files/docker-compose.yaml` - for working with Ansible (usually the same as EC2)
