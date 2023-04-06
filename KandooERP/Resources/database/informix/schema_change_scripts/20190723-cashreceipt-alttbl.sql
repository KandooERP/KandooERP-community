--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: cashreceipt
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table cashreceipt modify bank_code nchar(9);
alter table cashreceipt modify cash_acct_code nchar(18);
alter table cashreceipt modify cust_code nchar(8);
alter table cashreceipt modify entry_code nchar(8);
