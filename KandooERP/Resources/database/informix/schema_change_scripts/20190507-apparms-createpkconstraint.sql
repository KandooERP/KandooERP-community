--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: apparms
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_apparms on apparms(parm_code,cmpy_code);
ALTER TABLE apparms ADD CONSTRAINT PRIMARY KEY ( parm_code,cmpy_code)
CONSTRAINT pk_apparms
