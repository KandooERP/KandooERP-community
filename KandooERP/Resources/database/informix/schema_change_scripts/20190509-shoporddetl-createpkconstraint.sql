--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list:shoporddetl
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_shoporddetl on shoporddetl(shop_order_num,sequence_num,suffix_num,cmpy_code);
alter table shoporddetl add constraint primary key (shop_order_num,sequence_num,suffix_num,cmpy_code) constraint pk_shoporddetl;
