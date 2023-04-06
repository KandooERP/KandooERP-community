--# description: this script redefines the primary key constraint by adding one column 
--# dependencies: n/a
--# tables list: prodinfo
--# author: spokey/eric
--# date: 2020-11-09
--# Ticket # : 
--# 
alter table prodinfo add (line_num SMALLINT);
update prodinfo SET line_num = 1 WHERE line_num IS NULL ;
alter table prodinfo drop constraint pk_prodinfo;
drop index if exists pk_prodinfo;
create unique index "informix".pk_prodinfo on "informix".prodinfo (part_code,line_num,cmpy_code) using btree ;
alter table "informix".prodinfo add constraint primary key (part_code,line_num,cmpy_code) constraint "informix".pk_prodinfo  ;
