--# description: changing chars to Nchars
--# dependencies:
--# tables list: dangerclass
--# author: huho
--# date: 2019-04-02
--# Ticket # :
--# more comments: 

begin work;

drop table "informix".dangerclass;
create table "informix".dangerclass
 (
   class_code nchar(4),
   desc_text nvarchar(50)
 );

LOAD FROM "unl/20190402_dangerclass.unl" INSERT INTO dangerclass;

create unique index "informix".dangerclass_key on "informix".dangerclass
    (class_code) using btree ;
 

commit work;
