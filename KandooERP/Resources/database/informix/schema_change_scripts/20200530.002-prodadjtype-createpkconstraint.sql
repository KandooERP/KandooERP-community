--# description: this script creates a primary key for prodadjtype
--# tables list: prodadjtype
--# author: ericv
--# date: 2020-05-30
--# Ticket # : 	
--# dependencies:
--# more comments:

create unique index if not exists pk_prodadjtype on prodadjtype (adj_type_code,cmpy_code);
alter table prodadjtype add constraint primary key(adj_type_code,cmpy_code) constraint pk_prodadjtype;