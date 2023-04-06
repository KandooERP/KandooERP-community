--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: role
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE role ADD CONSTRAINT PRIMARY KEY (
role_code,
class_name,
role_name
) CONSTRAINT pk_role;
