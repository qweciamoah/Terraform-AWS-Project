
user_data/db_server_setup.sh
!/bin/bash
# Install and configure Postgres (single node). This is a simple, non-production install.
yum update -y
amazon-linux-extras install -y postgresql14
yum install -y postgresql-server postgresql-contrib

# initialize DB
/usr/bin/postgresql-setup --initdb

# start and enable
systemctl enable postgresql
systemctl start postgresql

# set a simple password for postgres user (change immediately)
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'ChangeMe123!';"

# allow remote connections from private network (web servers) - append to pg_hba.conf
echo "host    all             all             10.0.0.0/16            md5" >> /var/lib/pgsql/data/pg_hba.conf
# allow listening on all interfaces
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
systemctl restart postgresql