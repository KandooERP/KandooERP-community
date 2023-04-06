--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: customerpart
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table customerpart modify cust_code nchar(8);
