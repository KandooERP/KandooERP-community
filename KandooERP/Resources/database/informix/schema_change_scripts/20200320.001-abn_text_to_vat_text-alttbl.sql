--# description: this script renames the field abn_text to vat_code (V.A.T) and extends to nchar(12)
--# tables list: company,customeraudit,customer,vendoraudit,vendor
--# dependencies: 20200319.000-abn_text-dependencies 
--# author: ericv
--# date: 2020-03-20
--# Ticket # : 	KD-1859
--# more comments:
rename column company.abn_div_text to vat_div_code;
rename column company.abn_text to vat_code;
alter table company modify vat_code nchar(12);
rename column customeraudit.abn_text to vat_code;
alter table customeraudit modify vat_code nchar(12);
rename column customer.abn_text to vat_code;
alter table customer modify vat_code nchar(12);
rename column vendor.abn_text to vat_code;
alter table vendor modify vat_code nchar(12);
rename column vendoraudit.abn_text to vat_code;
alter table vendoraudit modify vat_code nchar(12);
