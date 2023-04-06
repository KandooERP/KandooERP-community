--# description: this script changes a unique index to duplicate
--# dependencies: 
--# tables list:  orderhead
--# author: erve
--# date: 2021-06-01
--# Ticket: 
--# more comments:

drop index if exists ord_key ;
create index d_orderhead_02 on orderhead(cust_code,cmpy_code);
