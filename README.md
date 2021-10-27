# Madoc config

If you want to try madoc out locally, and have Docker installed you can clone this repository and run:
```
docker-compose up -d
```

This will set up and create a local instance of Madoc. By default, the installation code required to proceed through the
setup process is `password`.

## Local
If you want to run a local instance of Madoc that will correctly persist files/database, you can use the local
configuration inside of `./local` and then from inside that folder run:
```
docker-compose up -d
```

## EC2
See [EC2 README.md](./ec2/README.md)

## Ansible
See [Ansible README.md](./ansible/README.md)

### Installation code
To secure a setup, you should generate your own installation code. This code is required when you first install
madoc on a server and allows you to set up your Administrator user and first site. Note: You need `node` installed.

Run:
```
node ./tools/install-code.js
```

And follow the instructions.

## Updating docker-compose definitions

There are the following docker-compose files that need to be updated:

- `./docker-compose.yaml` - completely standalone
- `./local/docker-compose.yaml` - local with local volumes
- `./ec2/docker-compose.yaml` - for working on a linux EC2
- `./ansbile/files/docker-compose.yaml` - for working with Ansible (usually the same as EC2)
