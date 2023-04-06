--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: structure
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/structure.bck
select * from structure;
drop table structure;
create table structure
  (
    cmpy_code char(2),
    start_num smallint,
    length_num smallint,
    desc_text nvarchar(20),
    default_text nvarchar(18),
    type_ind nchar(1)
  );

revoke all on structure from "public" as "informix";
load from /tmp/structure.bck
insert into structure;

create unique index u_structure on structure(start_num,cmpy_code);
alter table structure add constraint primary key (start_num,cmpy_code) constraint pk_structure;
