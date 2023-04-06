--# description: this script foreign keys on invoicehead to orderhead
--# dependencies: 
--# tables list:  invoicehead,orderhead
--# author: Eric Vercelletto
--# date: 2021-05-01
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table invoicehead  add constraint foreign key (ord_num,cmpy_code) references  orderhead (order_num,cmpy_code)  constraint fk_invoicehead_orderhead;
