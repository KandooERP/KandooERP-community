--# description: this script re-create primary key for customertype table 
--# tables list: customertype
--# author: albo
--# date: 2019-11-28
--# Ticket # : 	
--# more comments:
begin work;
   drop index if exists u_customertype;
   alter table customertype drop constraint pk_customertype;
   create unique index u_customertype on customertype (type_code,cmpy_code);
   alter table customertype add constraint primary key (type_code,cmpy_code) constraint pk_customertype;
commit work;
