--# description: this script gives some consistency to category columns related to coa
--# dependencies: 
--# tables list:  category
--# author: Eric Vercelletto
--# date: 2020-12-08
--# Ticket: 
--# more comments:
alter table category modify (pur_acct_code nchar(18),sale_acct_code nchar(18),cred_acct_code nchar(18),cogs_acct_code nchar(18),stock_acct_code nchar(18));