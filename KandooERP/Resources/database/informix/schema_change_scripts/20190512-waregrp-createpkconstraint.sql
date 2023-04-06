--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: waregrp
--# author: ericv
--# date: 2019-05-12
--# Ticket # :  4
--# more comments:
create unique index u_waregrp on waregrp(waregrp_code,cmpy_code);
alter table waregrp add constraint primary key (waregrp_code,cmpy_code) constraint pk_waregrp;
