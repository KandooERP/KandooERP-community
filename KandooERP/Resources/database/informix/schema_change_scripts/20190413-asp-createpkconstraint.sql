--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: asp
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE asp ADD CONSTRAINT PRIMARY KEY (
contact_id,
tmp_loginname,
server_instance,
max_db
) CONSTRAINT pk_asp;
