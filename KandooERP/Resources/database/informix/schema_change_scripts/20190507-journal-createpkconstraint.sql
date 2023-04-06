--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: journal
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_journal on journal(jour_code,cmpy_code);
ALTER TABLE journal ADD CONSTRAINT PRIMARY KEY ( jour_code,cmpy_code)
CONSTRAINT pk_journal;
