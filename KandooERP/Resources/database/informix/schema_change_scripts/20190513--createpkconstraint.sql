--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: userref
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_userref on userref(ref_code,source_ind,cmpy_code);
alter table userref add constraint primary key (ref_code,source_ind,cmpy_code) constraint pk_userref;
