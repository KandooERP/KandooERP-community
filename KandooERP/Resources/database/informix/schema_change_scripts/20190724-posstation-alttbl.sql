--# description: this script aligns datatypes for acct_code in all kandoodb
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: posstation
--# author: eric vercelletto
--# date: 2019-07-24
--# Ticket # :
--# more comments:
alter table posstation modify station_code nchar(8);
