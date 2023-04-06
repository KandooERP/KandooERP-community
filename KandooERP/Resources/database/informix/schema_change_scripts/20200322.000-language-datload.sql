--# description: this script reloads the language table with some additional details
--# dependencies: 
--# tables list:  language
--# author: ericv
--# date: 2020-03-24
--# Ticket: 
--# more comments: 
--# set constraints all deferred is necessary 
set constraints all deferred;
delete from language where 1 =1 ;
load from unl/20200322-language.unl insert into language;
commit work;
