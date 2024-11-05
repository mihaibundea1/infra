-- initscripts/A_initUsers.sql
CREATE DATABASE IF NOT EXISTS exercises;
CREATE USER IF NOT EXISTS exercises@'%' IDENTIFIED BY 'exercises1!';
GRANT ALL PRIVILEGES ON exercises.* TO exercises@'%';
FLUSH PRIVILEGES;