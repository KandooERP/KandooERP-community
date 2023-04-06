--# description: this script foreign keys on vendortype to coa
--# dependencies: 
--# tables list:  vendortype,coa
--# author: Eric Vercelletto
--# date: 2020-12-27
--# Ticket: 
--# more comments:
alter table vendortype add constraint foreign key (pay_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_vendortype_coa_pay;
alter table vendortype add constraint foreign key (freight_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_vendortype_coa_freight;
alter table vendortype add constraint foreign key (salestax_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_vendortype_coa_salestax;
alter table vendortype add constraint foreign key (disc_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_vendortype_coa_disc;
alter table vendortype add constraint foreign key (exch_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_vendortype_coa_exch;
