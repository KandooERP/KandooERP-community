--# description: this script adds country_code to strings translation and its primary key
--# dependencies: N/A
--# tables list:  application_strings,strings_translation
--# author: Eric Vercelletto
--# date: 2021-03-04
--# Ticket: KD-2657
--# more comments: 
--# 
insert into country (country_code,country_text) VALUES ("*"," All countries");  
alter table strings_translation add (country_code CHAR(3) before translation);
update strings_translation set country_code = "*" WHERE country_code is null;        -- column part of prykey, cannot be null
alter table strings_translation drop constraint pk_strings_translation ;
drop index if exists u_strings_translation;
create unique index u_strings_translation on strings_translation (string_id,language_code,country_code) using btree;
alter table strings_translation add constraint primary key (string_id,language_code,country_code) constraint pk_strings_translation ;