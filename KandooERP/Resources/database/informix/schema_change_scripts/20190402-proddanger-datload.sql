--# description: changing chars to Nchars
--# dependencies:
--# tables list: proddanger
--# author: huho
--# date: 2019-04-02
--# Ticket # :
--# more comments: changing chars to Nchars

begin work;

drop table "informix".proddanger;
create table "informix".proddanger
 (
   cmpy_code char(2),
   dg_code nchar(3),
   tech_text nvarchar(40),
   class_code nchar(4),
   un_num_text nchar(8),
   pkg_code nchar(3),
   con_text nchar(10),
   hazchem_code nchar(3)
 );

LOAD FROM "unl/20190402_proddanger.unl" INSERT INTO proddanger;
create unique index "informix".proddanger_key on "informix".proddanger
    (dg_code,cmpy_code) using btree ;
 

commit work;
