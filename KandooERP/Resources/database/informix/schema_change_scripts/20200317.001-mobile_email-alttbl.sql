--# description: this script add the fields mobile_phone and email to relevant tables
--# tables list: cfwdaudit,company,customer,customeraudit,customership,delivhead,invoicehead,jmj_impresttran,labourer,location,mtopvmst,ordcallfwd,orderaudit,orderhead,ordhead,ordquote,ordquotext,poscacust,postinvhead,postranhead,purchhead,quotehead,salesperson,subhead
--# dependencies: 20200317.000-mobile_email-dependencies
--# author: ericv
--# date: 2020-03-17
--# Ticket # : 	KD-1764
--# more comments: this patch is divided into 2 parts due to tables list lenght limited to varchar(255)


alter table cfwdaudit add mobile_phone char(20) ,add email varchar(128) ;
alter table company add mobile_phone char(20) before curr_code,add email varchar(128) before curr_code;
alter table customer add mobile_phone nchar(20) before cred_limit_amt,add email varchar(128) before cred_limit_amt;
alter table customeraudit add mobile_phone nchar(20) before cred_limit_amt,add email varchar(128) before cred_limit_amt;
alter table customership add mobile_phone nchar(20) before ware_code,add email varchar(128) before ware_code;
alter table delivhead add mobile_phone nchar(20) before ship_addr1_text,add email varchar(128) before ship_addr1_text;
alter table invoicehead add mobile_phone nchar(20) before invoice_to_ind,add email varchar(128) before invoice_to_ind;
alter table jmj_impresttran add mobile_phone nchar(20) before invoice_to_ind,add email varchar(128) before invoice_to_ind;
alter table labourer add mobile_phone nchar(20) before labour_class_code,add email varchar(128) before labour_class_code;
alter table location add mobile_phone nchar(20) before fax_text,add email varchar(128) before fax_text;
alter table mtopvmst add mobile_phone nchar(20) before acct_text,add email varchar(128) before acct_text;
alter table ordcallfwd add mobile_phone nchar(20) ,add email varchar(128) ;
alter table orderaudit add mobile_phone nchar(20) before ship_addr1_text,add email varchar(128) before ship_addr1_text;
alter table orderhead add mobile_phone nchar(20) before ord_ind,add email varchar(128) before ord_ind;
alter table ordhead add mobile_phone nchar(20) before ship_addr1_text,add email varchar(128) before ship_addr1_text;
alter table ordquote add mobile_phone nchar(20) before ship_addr1_text,add email varchar(128) before ship_addr1_text;
alter table ordquotext add mobile_phone nchar(20) before enter_quote_ind,add email varchar(128) before enter_quote_ind;
alter table poscacust add mobile_phone nchar(20) before fax_text,add email varchar(128) before fax_text;
alter table postinvhead add mobile_phone nchar(20) before invoice_to_ind,add email varchar(128) before invoice_to_ind;
alter table postranhead add mobile_phone nchar(20) before invoice_to_ind,add email varchar(128) before invoice_to_ind;
alter table purchhead add mobile_phone nchar(20) ,add email varchar(128) ;
alter table quotehead add mobile_phone nchar(20) before ware_code,add email varchar(128) before ware_code;
alter table salesperson add mobile_phone nchar(20) before com1_text,add email varchar(128) before com1_text;
alter table subhead add mobile_phone nchar(20) before sub_ind,add email varchar(128) before sub_ind;
