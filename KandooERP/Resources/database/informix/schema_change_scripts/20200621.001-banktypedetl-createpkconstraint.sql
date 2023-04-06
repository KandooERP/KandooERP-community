--# description: this script creates primary key for banktypedetl table
--# tables list: banktypedetl
--# author: albo
--# date: 2020-06-21
--# Ticket # KD-2121 	

on exception -623 status=OKE;
alter table banktypedetl drop constraint pk_banktypedetl;
drop index if exists u_banktypedetl;
create unique index if not exists u_banktypedetl on banktypedetl (type_code,bank_ref_code);
alter table banktypedetl add constraint primary key (type_code,bank_ref_code) constraint pk_banktypedetl;	
