--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: territory
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_territory on territory(terr_code,cmpy_code);
alter table territory add constraint primary key (terr_code,cmpy_code) constraint pk_territory;
