--# description: this script creates the table state and insert initial data from France and Ukraine
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: state
--# author: eric vercelletto
--# date: 2019-07-02
--# Ticket # :
--# more comments: this table can hold states/provinces/regions/lander etc, anything that is between the country and smaller divisions
drop table if exists state ;
create table state (
country_code nchar(3),
state_code nchar(6),
state_code_iso366_2 nchar(10),
state_text nchar(30),
state_text_enu nchar(30)
) ;

load from unl/20190722-state.unl insert into state ;
create unique index u_state on state(state_code,country_code);
create index i_state_01 on state(country_code);
create index i_state_02 on state(state_text);

alter table state add constraint primary key (state_code,country_code) constraint pk_state;
alter table state add constraint foreign key (country_code) references country (country_code) constraint fk_state_country;
