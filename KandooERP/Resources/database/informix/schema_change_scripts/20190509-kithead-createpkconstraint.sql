--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: kithead
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_kithead on kithead(kit_code,cmpy_code);
alter table kithead add constraint primary key (kit_code,cmpy_code) constraint pk_kithead;
