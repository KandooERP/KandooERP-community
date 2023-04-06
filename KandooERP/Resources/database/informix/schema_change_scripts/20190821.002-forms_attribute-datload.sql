--# description:  this script loads translation data
--# dependencies: none
--# tables list:  form_attributes,attributes_translation
--# author: Eric Vercelletto
--# date: 2019-08-19
--# Ticket # :
--# more comments: first backup the existing contents (unload to xxx.bkp), then update kandoouser table.

truncate table form_attributes;
load from unl/20190821-form_attributes.unl insert into form_attributes;
truncate table attributes_translation;
load from unl/20190821-attributes_translation.unl insert into attributes_translation;
