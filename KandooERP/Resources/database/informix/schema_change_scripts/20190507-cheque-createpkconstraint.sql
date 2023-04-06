--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cheque
--# author: ericv
--# date: 2019-05-06
--# Ticket # : 4
--# 

drop index if exists u_cheque;
--alter table cheque drop constraint pk_cheque ;
create unique index u_cheque on cheque(vend_code,cheq_code,cmpy_code);
ALTER TABLE cheque ADD CONSTRAINT PRIMARY KEY (vend_code,cheq_code,cmpy_code)
CONSTRAINT pk_cheque;

