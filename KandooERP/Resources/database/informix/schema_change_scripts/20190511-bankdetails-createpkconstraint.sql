--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: bankdetails
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
drop index if exists bankdtl_key;
create unique index u_bankdetails on bankdetails(bank_code,sheet_num,seq_num,cmpy_code) using btree ;
alter table bankdetails add constraint primary key (bank_code,sheet_num,seq_num,cmpy_code) constraint pk_bankdetails;
