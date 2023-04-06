--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: term
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_term on term(term_code,cmpy_code);
ALTER TABLE term ADD CONSTRAINT PRIMARY KEY ( term_code,cmpy_code)
CONSTRAINT pk_term;
