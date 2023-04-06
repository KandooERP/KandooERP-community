--# description: this script creates a primary key for arparmext
--# dependencies: 
--# tables list:  arparmext
--# author: albo
--# date: 2021-03-30
--# Ticket: KD-2711
--# more comments:

create unique index if not exists u_arparmext on arparmext (cmpy_code);
alter table arparmext add constraint primary key (cmpy_code) constraint pk_arparmext;
