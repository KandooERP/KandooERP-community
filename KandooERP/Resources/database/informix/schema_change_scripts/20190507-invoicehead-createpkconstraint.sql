--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: invoicehead
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_invoicehead on invoicehead(inv_num,cmpy_code);
ALTER TABLE invoicehead ADD CONSTRAINT PRIMARY KEY ( inv_num,cmpy_code)
CONSTRAINT pk_invoicehead;
