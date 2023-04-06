--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: conddisc
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_conddisc on conddisc(cond_code,cmpy_code);
alter table conddisc add constraint primary key (cond_code,cmpy_code) constraint pk_conddisc;
