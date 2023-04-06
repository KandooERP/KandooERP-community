--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: ingroup
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/ingroup.bck
select * from ingroup;
drop table ingroup;

create table "informix".ingroup
  (
    cmpy_code char(2),
    type_ind nchar(1),
    ingroup_code nvarchar(15),
    desc_text nvarchar(40)
  );

revoke all on ingroup from "public" as "informix";
load from /tmp/ingroup.bck
insert into ingroup;

create unique index u_ingroup on ingroup (ingroup_code,type_ind,cmpy_code);
alter table ingroup add constraint primary key (ingroup_code,type_ind,cmpy_code) constraint pk_ingroup;
