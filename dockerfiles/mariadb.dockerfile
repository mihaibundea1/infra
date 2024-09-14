FROM mariadb:latest

ADD ./initUsers.sql /docker-entrypoint-initdb.d
