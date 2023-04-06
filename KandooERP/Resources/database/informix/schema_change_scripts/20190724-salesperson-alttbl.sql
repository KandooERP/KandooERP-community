--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: salesperson
--# author: eric vercelletto
--# date: 2019-07-24
--# Ticket # :
--# more comments:
alter table salesperson modify sale_code nchar(8);
alter table salesperson modify terri_code nchar(5);
alter table salesperson modify state_code nchar(6);
alter table salesperson modify mgr_code nchar(8);
alter table salesperson modify post_code nchar(10);
