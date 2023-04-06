--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: debithead
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_debithead on debithead(debit_num,cmpy_code);
ALTER TABLE debithead ADD CONSTRAINT PRIMARY KEY ( debit_num,cmpy_code)
CONSTRAINT pk_debithead;
