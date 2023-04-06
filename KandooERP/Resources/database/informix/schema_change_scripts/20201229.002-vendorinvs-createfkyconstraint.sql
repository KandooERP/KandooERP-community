--# description: this script creates a foreign key for vendorinvs to voucher ( 1 to 1 relationship)
--# dependencies: 
--# tables list:  vendorinvs,voucher
--# author: Eric Vercelletto
--# date: 2020-12-29
--# Ticket: 
--# more comments:

alter table vendorinvs add constraint foreign key (vouch_code,cmpy_code) references voucher (vouch_code,cmpy_code) constraint fk_vendorinvs_voucher ;