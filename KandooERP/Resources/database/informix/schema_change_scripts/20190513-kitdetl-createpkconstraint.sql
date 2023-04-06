--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: kitdetl
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_kitdetl on kitdetl(kit_code,line_num,cmpy_code);
alter table kitdetl add constraint primary key (kit_code,line_num,cmpy_code) constraint pk_kitdetl;
