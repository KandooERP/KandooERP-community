--# description: this script fixes pay_acct_code data types
--# dependencies: 
--# tables list:  apparms
--# author: Eric Vercelletto
--# date: 2020-12-27
--# Ticket: 
--# more comments:
alter table apparms modify (pay_acct_code nchar(18));