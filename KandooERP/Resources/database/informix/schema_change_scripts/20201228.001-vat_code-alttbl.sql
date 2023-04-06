--# description: this script set all vat_code to CHAR(14)
--# dependencies: 
--# tables list:  vendoraudit,vendor,company,customer,customeraudit
--# author: Eric Vercelletto
--# date: 2020-12-28
--# Ticket: 
--# more comments:
alter table vendoraudit modify (vat_code nchar(14));
alter table vendor modify (vat_code nchar(14));
alter table company modify (vat_code nchar(14));
alter table customer modify (vat_code nchar(14));
alter table customeraudit modify (vat_code nchar(14));