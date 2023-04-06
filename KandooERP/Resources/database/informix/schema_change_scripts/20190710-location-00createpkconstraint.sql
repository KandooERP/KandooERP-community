--# description: this script creates a unique index and a primary key constraint on location
--# dependencies: 
--# tables list: location
--# author: eric vercelletto
--# date: 2019-07-10
--# Ticket # :
--# more comments:
create unique index if not exists u_location on location(locn_code,cmpy_code);
alter table location add constraint primary key (locn_code,cmpy_code) constraint pk_location ;
