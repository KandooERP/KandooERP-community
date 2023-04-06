--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: uom
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/uom.bck
select * from uom;
drop table uom;

create table uom
  (
    cmpy_code char(2),
    uom_code nchar(4),
    desc_text nvarchar(30)
  );

revoke all on uom from "public" as "informix";
load from /tmp/uom.bck
insert into uom;

create unique index u_uom on uom(uom_code,cmpy_code);
alter table uom add constraint primary key (uom_code,cmpy_code) constraint pk_uom;
