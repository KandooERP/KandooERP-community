--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: customer
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table customer modify bank_acct_code nchar(18);
alter table customer modify territory_code nchar(5);
alter table customer modify state_code nchar(6);
alter table customer modify post_code nchar(10);
alter table customer modify ref1_code nchar(10);
alter table customer modify ref2_code nchar(10);
alter table customer modify ref3_code nchar(10);
alter table customer modify ref4_code nchar(10);
alter table customer modify ref5_code nchar(10);
alter table customer modify ref6_code nchar(10);
alter table customer modify ref7_code nchar(10);
alter table customer modify ref8_code nchar(10);
