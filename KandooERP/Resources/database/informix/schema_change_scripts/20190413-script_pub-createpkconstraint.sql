--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: script_pub
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE script_pub ADD CONSTRAINT PRIMARY KEY (
publisher
) CONSTRAINT pk_script_pub;
