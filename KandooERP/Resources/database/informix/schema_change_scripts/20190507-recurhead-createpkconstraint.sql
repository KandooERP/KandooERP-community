--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: recurhead
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_recurhead on recurhead(recur_code,cmpy_code);
ALTER TABLE recurhead ADD CONSTRAINT PRIMARY KEY ( recur_code,cmpy_code)
CONSTRAINT pk_recurhead;
