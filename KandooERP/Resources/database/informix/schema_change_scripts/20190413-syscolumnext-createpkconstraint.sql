--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: syscolumnext
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE syscolumnext ADD CONSTRAINT PRIMARY KEY (
owner,
tabname,
colname
) CONSTRAINT pk_syscolumnext;
