--# description: this script renames some columns of attributes_translation
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: attributes_translation
--# author: eric vercelletto
--# date: 2019-08-10
--# Ticket # :
--# more comments:
unload to unl/attributes_translation.unl select * from attributes_translation;
rename column attributes_translation.attribute_language to language;
rename column attributes_translation.attribute_translation to translation;
rename column attributes_translation.attribute_modif_timestamp to modif_timestamp;
update attributes_translation set modif_timestamp = NULL where 1 = 1 ;
alter table attributes_translation modify modif_timestamp datetime year to second;
--load from unl/attributes_translation.unl insert into attributes_translation;
