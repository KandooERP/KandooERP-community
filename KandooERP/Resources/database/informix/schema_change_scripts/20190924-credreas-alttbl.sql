--# description: this script re-create primary key for credreas table 
--# tables list: credreas
--# author: albo
--# date: 2019-09-24
--# Ticket # : 	
--# more comments:

begin work;
   drop index if exists u_credreas;
   create unique index "informix".u_credreas on "informix".credreas (reason_code,cmpy_code) using btree ;
   alter table credreas drop constraint pk_credreas;
   alter table credreas add constraint primary key (reason_code,cmpy_code) constraint pk_credreas;
commit work;

