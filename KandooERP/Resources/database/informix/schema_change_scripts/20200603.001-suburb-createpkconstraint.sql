--# description: this script create primary key for suburb table 
--# tables list: suburb
--# author: ericv
--# date: 2020-05-26
--# Ticket # : 	
--# dependencies:
--# more comments:

on exception -623 status=OKE;
alter table suburb drop constraint pk_suburb ;
drop index if exists suburb2_key;
create unique index if not exists pk_suburb on suburb(suburb_code,cmpy_code);
alter table suburb add constraint primary key (suburb_code,cmpy_code) constraint pk_suburb ;
on exception -623 status=OKE ;
--alter table suburb drop constraint u_suburb ;
drop index if exists suburb_key;
create unique index if not exists u_suburb  on suburb(suburb_text,post_code,cmpy_code);
alter table suburb add constraint unique (suburb_text,post_code,cmpy_code) constraint u_suburb  ;