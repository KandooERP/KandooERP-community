--# description: this script creates primary key for userlimits table
--# tables list: userlimits
--# author: ericv
--# date: 2020-09-29

create unique index if not exists ipk_userlimits on userlimits (sign_on_code,cmpy_code);
alter table userlimits add constraint primary key (sign_on_code,cmpy_code) constraint pk_userlimits;	
