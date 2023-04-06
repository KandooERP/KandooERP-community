--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: quotehead
--# author: spokey
--# date: 2019-05-08
--# Ticket # : 4
--# fixed columns order and u index name by ericv 

alter table quotehead drop constraint pk_quotehead  ;
drop index if exists quote_key;
create unique index if not exists u_quote on quotehead (order_num,cust_code,cmpy_code) using btree ;
alter table quotehead add constraint primary key (order_num,cust_code,cmpy_code) constraint pk_quotehead  ;
