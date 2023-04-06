--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: product
--# author: eric vercelletto
--# date: 2019-07-24
--# Ticket # :
--# more comments:
alter table product modify ref1_code nchar(10);
alter table product modify ref2_code nchar(10);
alter table product modify ref3_code nchar(10);
alter table product modify ref4_code nchar(10);
alter table product modify ref5_code nchar(10);
alter table product modify ref6_code nchar(10);
alter table product modify ref7_code nchar(10);
alter table product modify ref8_code nchar(10);
alter table product modify price_uom_code nchar(4);
