--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: credheadaddr
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
--alter table credheadaddr modify bank_code nchar(9);
alter table credheadaddr modify cmpy_code nchar(2);
