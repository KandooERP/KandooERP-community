--# description: this script alters data type of  abn_text
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  company
--# author: eric vercelletto
--# date: 2019-07-23
--# Ticket # :
--# more comments:
alter table company modify abn_text nchar(11);
alter table company modify state_code nchar(6);
alter table company modify post_code nchar(10);
