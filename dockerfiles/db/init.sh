#!/bin/bash
set -e

echo "host all  all  172.25.0.0/16  md5" >> /var/lib/postgresql/data/pg_hba.conf
cat >> /var/lib/postgresql/data/postgresql.conf<< EOF
shared_buffers = 512MB
effective_cache_size = 1GB
work_mem = 128MB
EOF

