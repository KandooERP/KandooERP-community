--# description: this script foreign keys on apparms to coa
--# dependencies: 
--# tables list:  apparms,coa
--# author: Eric Vercelletto
--# date: 2020-12-27
--# Ticket: 
--# more comments:
alter table apparms add constraint foreign key (pay_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_apparms_coa_pay;
alter table apparms add constraint foreign key (bank_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_apparms_coa_bank;
alter table apparms add constraint foreign key (salestax_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_apparms_coa_salestax;
alter table apparms add constraint foreign key (disc_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_apparms_coa_disc;
alter table apparms add constraint foreign key (exch_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_apparms_coa_exch;
alter table apparms add constraint foreign key (freight_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_apparms_coa_freight;