--# description: this script foreign keys on jmparms to coa
--# dependencies: 
--# tables list:  jmparms,coa
--# author: Eric Vercelletto
--# date: 2021-22-28
--# Ticket: KD-2687
--# more comments:

alter table jmparms add constraint foreign key (susp_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_jmparms_coa_susp;