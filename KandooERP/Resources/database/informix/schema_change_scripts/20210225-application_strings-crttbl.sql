--# description: this script creates the 2 tables in charge of the new strings translation
--# dependencies: N/A
--# tables list:  application_strings,strings_translation
--# author: Eric Vercelletto
--# date: 2021-02-25
--# Ticket: KD-2657
--# more comments: 
--# 

create table application_strings
  (
    string_id integer,
    container varchar(24,6),
    string_type char(10),
    string_contents lvarchar(256),
    string_hash CHAR(20)
  );

create unique index u_application_strings on application_strings (string_id) using btree ;
alter table application_strings add constraint primary key (string_id) constraint pk_application_strings ;

create table strings_translation
  (
    string_id integer,
    language_code char(3),
    translation lvarchar(256),
    last_modification_ts DATETIME YEAR TO SECOND
  );

create unique index u_strings_translation on strings_translation (string_id,language_code) using btree;
alter table strings_translation add constraint primary key (string_id,language_code) constraint pk_strings_translation ;

alter table strings_translation add constraint (foreign key (string_id) references application_strings constraint fk_strings_translation_application_strings);
