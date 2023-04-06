--# description: this script foreign keys on invoicehead to coa
--# dependencies: 
--# tables list:  invoicehead,coa
--# author: Eric Vercelletto
--# date: 2021-05-01
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table invoicehead  add constraint foreign key (acct_override_code,cmpy_code) references  coa (acct_code,cmpy_code)  constraint fk_invoicehead_coa;