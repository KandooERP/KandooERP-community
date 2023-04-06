--# description: this script add foreign keys on customertype 
--# dependencies:
--# tables list: customertype,coa
--# author: eric
--# date: 2020-12-26
--# Ticket # : 
--# 

alter table customertype add constraint foreign key (ar_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_customertype_coa_ar;
alter table customertype add constraint foreign key (freight_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_customertype_coa_freight;
alter table customertype add constraint foreign key (tax_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_customertype_coa_tax;
alter table customertype add constraint foreign key (disc_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_customertype_coa_disc;
alter table customertype add constraint foreign key (exch_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_customertype_coa_exch;
alter table customertype add constraint foreign key (lab_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_customertype_coa_lab;
alter table customertype add constraint foreign key (acct_mask_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_customertype_coa_mask;