--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: validflex
--# author: ericv
--# date: 2019-05-10
--# Ticket # :  4
--# more comments:
create unique index u_validflex on validflex(flex_code,start_num,cmpy_code);
alter table validflex add constraint primary key (flex_code,start_num,cmpy_code) constraint pk_validflex;
