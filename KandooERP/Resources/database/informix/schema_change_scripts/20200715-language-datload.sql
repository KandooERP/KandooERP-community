--# description: this script loads data to language
--# tables list: language
--# dependencies: 
--# author: ericv
--# date: 2020-07-15
--# Ticket #  KD-1960
SET CONSTRAINTS ALL DEFERRED;
unload to unl/kandoouser.unl select * from kandoouser where language_code not in ("ENG","FRA");
delete from kandoouser where  language_code not in ("ENG","FRA");
DELETE FROM  language WHERE 1=1;
load from unl/languages-ISO-639-2.unl insert into language;

