--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: pricing
--# author: eric vercelletto
--# date: 2019-07-24
--# Ticket # :
--# more comments:
alter table pricing modify part_code nchar(15);
