--# description: this script fixes datatype of vend_code and related
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  debithead
--# author: you
--# date: 2019-07-22
--# Ticket # :
--# more comments:
alter table debithead modify vend_code nchar(8);
alter table debithead modify entry_code nchar(8);
