--# description: this script creates a foreign key constraint from voucherdist to voucher
--# dependencies: n/a
--# tables list: voucherdist
--# author: ericv
--# date: 2020-05-28
--# Ticket # : 
--# 
create index d02_voucherdist on voucherdist (vouch_code, cmpy_code);
ALTER TABLE voucherdist ADD CONSTRAINT FOREIGN KEY (vouch_code, cmpy_code) references voucher(vouch_code, cmpy_code) CONSTRAINT fk_voucherdist_voucher;

