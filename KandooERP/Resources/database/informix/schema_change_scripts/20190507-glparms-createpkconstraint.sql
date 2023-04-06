--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: glparms
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_glparms on glparms(key_code,cmpy_code);
ALTER TABLE glparms ADD CONSTRAINT PRIMARY KEY ( key_code,cmpy_code)
CONSTRAINT pk_glparms;
