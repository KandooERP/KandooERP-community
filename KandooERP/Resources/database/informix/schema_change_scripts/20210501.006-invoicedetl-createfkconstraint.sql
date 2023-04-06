--# description: this script foreign keys on invoicedetl to tax
--# dependencies: 
--# tables list:  invoicedetl,tax
--# author: Eric Vercelletto
--# date: 2021-05-01
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table invoicedetl  add constraint foreign key (tax_code,cmpy_code) references  tax (tax_code,cmpy_code)  constraint fk_invoicedetl_tax;