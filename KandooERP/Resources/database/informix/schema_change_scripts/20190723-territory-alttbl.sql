--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: territory
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table territory modify area_code nchar(5);
alter table territory modify sale_code nchar(8);
alter table territory modify terr_code nchar(5);
