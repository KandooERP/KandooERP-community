--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: binding
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE binding ADD CONSTRAINT PRIMARY KEY (
bind_code
) CONSTRAINT pk_binding;
