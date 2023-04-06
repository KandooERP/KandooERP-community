--# description: this script create indexes and constraints on cartarea
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: cartarea
--# author: eric vercelletto
--# date: 2019-08-20
--# Ticket # :
--# more comments:
create index i01_cartarea on cartarea(cmpy_code);
alter table cartarea add constraint foreign key (cmpy_code) references company(cmpy_code) constraint fk_cartarea_company ;

