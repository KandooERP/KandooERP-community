--# description: this script create primary key for prodledg table 
--# tables list: prodledg
--# author: ericv
--# date: 2020-05-26
--# Ticket # : 	
--# dependencies:
--# more comments:

on exception -623 status=OKE;
alter table prodledg drop constraint pk_prodledg;
drop index if exists u_prodledg ;
create unique index u_prodledg on prodledg(part_code,ware_code,seq_num,cmpy_code);
alter table prodledg add constraint primary key (part_code,ware_code,seq_num,cmpy_code) constraint "informix".pk_prodledg  ;