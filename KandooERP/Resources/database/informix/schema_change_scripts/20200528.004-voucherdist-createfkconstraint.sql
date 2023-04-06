--# description: this script creates a foreign key constraint from voucherdist to coa
--# dependencies: n/a
--# tables list: voucherdist
--# author: ericv
--# date: 2020-05-28
--# Ticket # : 
--# 
create index d03_voucherdist on voucherdist (acct_code, cmpy_code);
ALTER TABLE voucherdist ADD CONSTRAINT FOREIGN KEY (acct_code, cmpy_code) references coa(acct_code, cmpy_code) CONSTRAINT fk_voucherdist_coa;
drop index voucd_key4 ;
drop index voucd_key;