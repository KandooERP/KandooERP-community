--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: warehouse
--# author: eric vercelletto
--# date: 2019-07-24
--# Ticket # :
--# more comments:
alter table warehouse modify state_code nchar(6);
alter table warehouse modify waregrp_code nchar(8);
alter table warehouse modify post_code nchar(10);
