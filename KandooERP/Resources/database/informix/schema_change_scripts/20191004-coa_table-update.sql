--# description:  This script modifies data in the table coa. 
--# dependencies: none
--# tables list:  coa
--# author: Alex Bondar
--# date: 2019-10-04
--# Ticket # KD-1274:
--# more comments: Rubbish is remove from the coa.tax_code column for "KandooERP Computer Systems" company.

update coa set tax_code = NULL where cmpy_code = "KA";
