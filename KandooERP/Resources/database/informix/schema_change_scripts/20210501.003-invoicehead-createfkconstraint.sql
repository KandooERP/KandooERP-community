--# description: this script foreign keys on invoicehead to kandoouser
--# dependencies: 
--# tables list:  invoicehead,kandoouser
--# author: Eric Vercelletto
--# date: 2021-05-01
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table invoicehead  add constraint foreign key (entry_code,cmpy_code) references  kandoouser (sign_on_code,cmpy_code)  constraint fk_invoicehead_kandoouser;