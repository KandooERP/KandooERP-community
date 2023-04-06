--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list:shopordhead
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_shopordhead on shopordhead(shop_order_num,suffix_num,cmpy_code);
alter table shopordhead add constraint primary key (shop_order_num,suffix_num,cmpy_code) constraint pk_shopordhead;
