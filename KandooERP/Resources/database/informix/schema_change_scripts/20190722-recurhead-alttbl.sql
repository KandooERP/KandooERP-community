--# description: this script fixes datatype of vend_code and related
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  recurhead
--# author: you
--# date: 2019-07-22
--# Ticket # :
--# more comments:
alter table recurhead modify vend_code nchar(8)
