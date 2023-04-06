--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: pendhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE pendhead ADD CONSTRAINT PRIMARY KEY (
pend_num,
cmpy_code
) CONSTRAINT pk_pendhead;
