--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: loadparms
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
alter table loadparms drop constraint loadparms;
create unique index u_loadparms on loadparms(load_ind,cmpy_code);
alter table loadparms add constraint primary key (load_ind,cmpy_code) constraint pk_loadparms;
