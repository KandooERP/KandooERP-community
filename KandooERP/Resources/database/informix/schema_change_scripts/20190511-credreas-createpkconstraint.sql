--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: credreas
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_credreas on credreas(reason_code);
alter table credreas add constraint primary key (reason_code) constraint pk_credreas;
