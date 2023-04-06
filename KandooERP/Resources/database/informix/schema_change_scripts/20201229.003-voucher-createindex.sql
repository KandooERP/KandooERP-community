--# description: this script drops and creates index for voucher
--# dependencies: 
--# tables list:  voucher
--# author: Eric Vercelletto
--# date: 2020-12-29
--# Ticket: 
--# more comments:
drop index if exists d02_voucher;
create unique index u01_voucher on voucher(inv_text,vend_code,cmpy_code);