--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: purchdetl
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
create unique index u_purchdetl on purchdetl(order_num,line_num,cmpy_code);
alter table purchdetl add constraint primary key (order_num,line_num,cmpy_code) constraint pk_purchdetl;
