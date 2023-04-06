--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: workcentre
--# author: ericv
--# date: 2019-05-10
--# Ticket # :  4
--# more comments:
create unique index u_workcentre on workcentre(work_centre_code,cmpy_code);
alter table workcentre add constraint primary key (work_centre_code,cmpy_code) constraint pk_workcentre;
