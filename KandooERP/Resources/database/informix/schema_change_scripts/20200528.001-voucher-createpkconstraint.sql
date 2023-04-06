--# description: this script creates a primary key for voucher
--# tables list: voucher
--# author: ericv
--# date: 2020-05-28
--# Ticket # : 	
--# dependencies:
--# more comments:

drop index if exists vouc2_key ;
create unique index if not exists pk_voucher on voucher (vouch_code,cmpy_code);
alter table voucher drop constraint pk_voucher;
alter table voucher add constraint primary key(vouch_code,cmpy_code) constraint pk_voucher;

create index d02_voucher on voucher (inv_text,vend_code);