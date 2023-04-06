--# description: this script alters data type of  abn_text
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  customer
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table customer modify abn_text nchar(11);
