--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: labelhead
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_labelhead on labelhead(label_code,cmpy_code);
alter table labelhead add constraint primary key (label_code,cmpy_code) constraint pk_labelhead;
