--# description: this script add a check constraint to invoicehead
--# dependencies: 
--# tables list:  invoicehead
--# author: Eric Vercelletto
--# date: 2021-01-02
--# Ticket: 
--# more comments:

alter table invoicehead add constraint check (inv_num > 0 ) constraint ck_invoicehead_inv_num;