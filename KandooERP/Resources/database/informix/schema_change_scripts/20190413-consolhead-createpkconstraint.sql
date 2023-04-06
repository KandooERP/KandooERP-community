--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: consolhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE consolhead ADD CONSTRAINT PRIMARY KEY (
consol_code,
cmpy_code
) CONSTRAINT pk_consolhead;
