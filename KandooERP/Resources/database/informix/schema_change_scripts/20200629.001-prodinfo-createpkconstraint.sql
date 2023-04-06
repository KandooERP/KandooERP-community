--# description: this script creates primary key for banktypedetl table
--# tables list: banktypedetl
--# author: ericv
--# date: 2020-09-29

create unique index if not exists ipk_prodinfo on prodinfo (part_code,cmpy_code);
alter table prodinfo add constraint primary key (part_code,cmpy_code) constraint pk_prodinfo;	
