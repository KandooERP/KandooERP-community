--# description: this script add the fields mobile_phone and email to relevant tables
--# tables list: supervisor,tentinvhead,tentsubhead,vendor,vendoraudit,warehouse
--# dependencies: 20200317.000-mobile_email-dependencies
--# author: ericv
--# date: 2020-03-17
--# Ticket # : 	KD-1764
--# more comments:


alter table supervisor  add mobile_phone nchar(20) ,add email varchar(128) ;
alter table tentinvhead add mobile_phone nchar(20) before invoice_to_ind,add email varchar(128) before invoice_to_ind;
alter table tentsubhead add mobile_phone nchar(20) before sub_ind,add email varchar(128) before sub_ind;
alter table vendor add mobile_phone nchar(20) before acct_text,add email varchar(128) before acct_text;
alter table vendoraudit add mobile_phone nchar(20) before limit_amt,add email varchar(128) before limit_amt;
alter table warehouse add mobile_phone nchar(20) before auto_run_num,add email varchar(128) before auto_run_num;
