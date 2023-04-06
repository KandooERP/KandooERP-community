--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: customertype
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table customertype modify acct_mask_code nchar(18);
alter table customertype modify ar_acct_code nchar(18);
alter table customertype modify disc_acct_code nchar(18);
alter table customertype modify exch_acct_code nchar(18);
alter table customertype modify freight_acct_code nchar(18);
alter table customertype modify lab_acct_code nchar(18);
alter table customertype modify tax_acct_code nchar(18);
