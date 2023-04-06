--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: bank
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table bank modify bank_code nchar(9);
alter table bank modify acct_code nchar(18);
alter table bank modify bic_code nchar(11);
