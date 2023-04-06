--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: condsale
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_condsale on condsale(cond_code,cmpy_code);
alter table condsale add constraint primary key (cond_code,cmpy_code) constraint pk_condsale;
