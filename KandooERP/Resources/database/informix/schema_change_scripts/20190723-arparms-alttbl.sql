--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: arparms
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table arparms modify ar_acct_code nchar(18);
alter table arparms modify cash_acct_code nchar(18);
alter table arparms modify disc_acct_code nchar(18);
alter table arparms modify exch_acct_code nchar(18);
alter table arparms modify freight_acct_code nchar(18);
alter table arparms modify lab_acct_code nchar(18);
alter table arparms modify tax_acct_code nchar(18);
