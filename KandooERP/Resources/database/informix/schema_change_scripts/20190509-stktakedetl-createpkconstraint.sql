--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: stktakedetl
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_stktakedetl on stktakedetl(cycle_num,ware_code,part_code,cmpy_code);
alter table stktakedetl add constraint primary key (cycle_num,ware_code,part_code,cmpy_code) constraint pk_stktakedetl;
