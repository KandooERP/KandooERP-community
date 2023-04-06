--# description: this script creates the new tables for chart of account template
--# tables list: coatemplthead,coatempltdetl
--# dependencies: 
--# author: ericv
--# date: 2020-06-24
--# Ticket #  KD-2239	

drop table if exists coatempltdetl ;
drop table if exists coatemplthead ;
create table coatemplthead
  (
    country_code char(3) not null ,
    language_code char(3) not null ,
    description nchar(80) not null ,
    last_revision date,
    comments lvarchar(1024)
  );

create unique index pk_coatemplthead on coatemplthead (country_code,language_code) using btree ;
alter table coatemplthead add constraint primary key (country_code,language_code) constraint pk_coatemplthead ;

create table coatempltdetl
  (
    acct_code char(18) not null ,
    description nchar(90) not null ,
    country_code char(3),
    language_code char(3),
    ifrs_equivalence char(18),
    tree_level char(1),
    acct_type char(1)
  );

create index d01_coatempltdetl on coatempltdetl (ifrs_equivalence) using btree ;
create unique index pk_coatempltdetl on coatempltdetl (acct_code,country_code,language_code) using btree ;

alter table coatempltdetl add constraint (foreign key (country_code,language_code) references coatemplthead constraint fk_coatempltdetl_coatemplthead);