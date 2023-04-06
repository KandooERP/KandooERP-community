--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: apparms
--# author: eric vercelletto
--# date: 2019-07-24
--# Ticket # :
--# more comments:
alter table apparms modify freight_acct_code nchar(18);
alter table apparms modify salestax_acct_code nchar(18);
alter table apparms modify pay_acct_code nchar(15);
alter table apparms modify disc_acct_code nchar(18);
alter table apparms modify exch_acct_code nchar(18);
