--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: prodledg
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
create unique index u_prodledg on prodledg(part_code,tran_date,ware_code,seq_num,cmpy_code);
alter table prodledg add constraint primary key (part_code,tran_date,ware_code,seq_num,cmpy_code) constraint pk_prodledg;
