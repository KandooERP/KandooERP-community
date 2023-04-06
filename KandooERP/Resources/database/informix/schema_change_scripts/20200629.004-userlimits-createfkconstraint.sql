--# description: this script creates foreign key for userlimits table to kandoouser
--# tables list: userlimits,kandoouser
--# author: ericv
--# date: 2020-09-29

alter table userlimits add constraint foreign key (sign_on_code,cmpy_code) references kandoouser (sign_on_code,cmpy_code) constraint fk_userlimits_kandoouser;	
