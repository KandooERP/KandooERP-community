--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies:
--# tables list: holdreas
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_holdreas on holdreas(hold_code,cmpy_code);
alter table holdreas add constraint primary key (hold_code,cmpy_code) constraint pk_holdreas;
