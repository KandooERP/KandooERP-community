--# description: this script create the tables necessary for messages and forms translation
--# dependencies: 
--# tables list: form_attributes,attributes_translation
--# author: ericv
--# date: 2019-05-01
--# Ticket # :
--# more comments:
drop table if exists "informix".qx_form_attributes ;
drop table if exists "informix".form_attributes ;
create table "informix".form_attributes 
  (
    attribute_key char(64),
    attribute_id integer,
    form_name char(20),
    tablename char(32),
    widget_id char(20),
    attribute_order char(12),
    widget_type char(15),
    attribute_type char(15)
  );

revoke all on "informix".form_attributes from "public" as "informix";


create unique index "informix".u_form_attr on "informix".form_attributes 
    (attribute_id) using btree ;
alter table "informix".form_attributes add constraint primary 
    key (attribute_id) constraint "informix".pk_form_attributes ;

drop table if exists "informix".qx_attributes_translation ;
drop table if exists "informix".attributes_translation ;
create table "informix".attributes_translation 
  (
    attribute_id integer,
    attribute_language char(3),
    attribute_translation nvarchar(255),
    attribute_modif_timestamp bigint 
  );

revoke all on "informix".attributes_translation from "public" as "informix";


create unique index "informix".u_attributes_translation on "informix".attributes_translation (attribute_id,attribute_language) 
    using btree ;
alter table "informix".attributes_translation add constraint 
    primary key (attribute_id,attribute_language) constraint 
    "informix".pk_attributes_translation  ;
