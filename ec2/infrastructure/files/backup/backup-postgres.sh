#! /bin/bash

docker exec -u postgres -i madoc_shared-postgres_1 pg_dump > shared-postgres.sql

/bin/chmod 644 shared-postgres.sql