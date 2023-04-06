--# description: this script modifies primary key for invoicepay table
--# tables list: invoicepay
--# author: ericv
--# date: 2020-02-10
--# Ticket # : 	
--# more comments:

alter table "informix".invoicepay drop constraint pk_invoicepay  ;
drop index if exists "informix".u_invoicepay ;
create unique index if not exists "informix".pk_invoicepay on "informix".invoicepay (appl_num) using btree ;
alter table "informix".invoicepay add constraint primary key (appl_num) constraint "informix" .pk_invoicepay  ;
create index if not exists "informix".d1_invoicepay on "informix".invoicepay (inv_num,cust_code,cmpy_code) using btree ;