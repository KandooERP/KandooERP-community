--# description: this script foreign keys on arparms to coa
--# dependencies: 
--# tables list:  arparms,coa
--# author: Eric Vercelletto
--# date: 2021-22-28
--# Ticket: KD-2688
--# more comments:
alter table arparms add constraint foreign key (cash_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_arparms_coa_cash;
alter table arparms add constraint foreign key (ar_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_arparms_coa_ar;
alter table arparms add constraint foreign key (freight_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_arparms_coa_freight;  
alter table arparms add constraint foreign key (tax_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_arparms_coa_tax; 
alter table arparms add constraint foreign key (disc_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_arparms_coa_disc; 
alter table arparms add constraint foreign key (exch_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_arparms_coa_exch;
alter table arparms add constraint foreign key (lab_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_arparms_coa_lab;