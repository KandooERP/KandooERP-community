--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: invoicehead
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table invoicehead modify area_code nchar(5);
alter table invoicehead modify acct_override_code nchar(18);
alter table invoicehead modify cust_code nchar(8);
alter table invoicehead modify entry_code nchar(8);
alter table invoicehead modify entry_code nchar(8);
alter table invoicehead modify job_code nchar(8);
alter table invoicehead modify job_code nchar(8);
alter table invoicehead modify job_code nchar(8);
alter table invoicehead modify ship_code nchar(8);
alter table invoicehead modify sale_code nchar(8);
alter table invoicehead modify territory_code nchar(5);
alter table invoicehead modify state_code nchar(6);
alter table invoicehead modify mgr_code nchar(8);
alter table invoicehead modify post_code nchar(10);
alter table invoicehead modify purchase_code nchar(30);
