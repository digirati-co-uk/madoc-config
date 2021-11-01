# EC2 Configuration

This sets up a Madoc instance running via docker-compose on a single EC2 machine.

## Resources

The Terraform scripts will the following resources:

A VPC with a single public subnet. This subnet has an internet gateway and allows traffic to ports 80 + 443 from anywhere. Access to port 22 is restricted to IP addresses specified in `egress_whitelist` variable (see [network.tf](/infrastructure/network.tf)).

A single EC2 instance with and Elastic IP address and 3 EBS volumes (see [ec2.tf](/infrastructure/ec2.tf)):

* Boot volume. Default size 30GB, can be controlled via `root_size` variable.
* Data volume, mounted as `/opt/data`. Default size 20GB, can be controlled via `ebs_size` variable.
* Backup volume, mounted as `/mnt/data`. Default size 30GB, can be controlled via `ebs_backup_size` variable.

The EC2 uses `user_data` to setup various systemd services for running services and backups (see [/files](/files/)). 

Systemd + rsync are used to take database and file snapshots to the backup volume at `/mnt/data`. There is then a [DLM](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/snapshot-lifecycle.html) policy setup to take snapshots of the backup volume. Default is to take 1 snapshot per day and keep the last 14 snapshots (see [backup.tf](/infrastructure/backup.tf)).

There is a single DNS A record setup to point to the above Elastic IP (see [dns.tf](/infrastructure/dns.tf)).

## Usage

Generate a keypair and replace `/infrastructure/files/key.pub` with the new file.

Search for "EXAMPLE_NAME" to find variables that need replaced.

Modify variable values to suit.

For more information see [readme](/infrastructure/readme.md)