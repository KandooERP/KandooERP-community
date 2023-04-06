--# description: this script foreign keys on invoicedetl to coa
--# dependencies: 
--# tables list:  invoicedetl,coa
--# author: Eric Vercelletto
--# date: 2021-05-01
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table invoicedetl  add constraint foreign key (line_acct_code,cmpy_code) references  coa (acct_code,cmpy_code)  constraint fk_invoicedetl_coa;