--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: holdpay
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_holdpay on holdpay(hold_code,cmpy_code);
ALTER TABLE holdpay ADD CONSTRAINT PRIMARY KEY ( hold_code,cmpy_code)
CONSTRAINT pk_holdpay;
