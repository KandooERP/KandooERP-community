--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: language
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
rename constraint  pk_language TO pk_qxt_language;
create unique index u_language on language(language_code);
alter table language add constraint primary key (language_code) constraint pk_language;
