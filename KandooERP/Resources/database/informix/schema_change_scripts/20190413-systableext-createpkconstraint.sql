--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: systableext
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE systableext ADD CONSTRAINT PRIMARY KEY (
owner,
tabname
) CONSTRAINT pk_systableext;
