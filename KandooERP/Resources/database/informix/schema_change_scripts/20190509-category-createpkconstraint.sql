--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: category
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_category on category(cat_code,cmpy_code);
alter table category add constraint primary key (cat_code,cmpy_code) constraint pk_category;
