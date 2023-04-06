--# description: this script fixes datatype of vend_code and related
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  vendortype
--# author: you
--# date: 2019-07-22
--# Ticket # :
--# more comments:
alter table vendortype modify tax_vend_code nchar(8) ;
alter table vendortype modify disc_acct_code nchar(18) ;
alter table vendortype modify exch_acct_code nchar(18) ;
alter table vendortype modify freight_acct_code nchar(18) ;
alter table vendortype modify disc_acct_code nchar(18);
alter table vendortype modify pay_acct_code nchar(18);
