--# description: this script fixes datatype of vend_code and related
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  arparmext
--# author: you
--# date: 2019-07-22
--# Ticket # :
--# more comments:
alter table arparmext modify int_acct_code nchar(18) ;
