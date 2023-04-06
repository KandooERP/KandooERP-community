--# description: this script handles changes in the menu items
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  menu_group_access
--# author: Alex Bondar
--# date: 2019-04-07
--# Ticket # :
begin work;

drop table "informix".menu_group_access;
create table "informix".menu_group_access
  (
    mb_id integer not null ,
    group_code nchar(1) not null ,
    ga_hidden integer,
    unique (mb_id,group_code) constraint "informix".u_group_access
  );

load from "unl/20190407_menu_group_access.unl" insert into menu_group_access;

alter table "informix".menu_group_access add constraint (foreign
    key (group_code) references "informix".qxt_user_group  constraint
    "informix".fk_group_access_group_code);
alter table "informix".menu_group_access add constraint (foreign
    key (mb_id) references "informix".qxt_menu_item  constraint
    "informix".fk_group_access_mb_id);

commit work;














