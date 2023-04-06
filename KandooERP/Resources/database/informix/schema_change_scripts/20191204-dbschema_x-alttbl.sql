--# description: this script adds database name as foreign key in dbschema_fix + creates PK and FK
--# tables list: dbschema_properties,dbschema_fix
--# author: ericv
--# date: 2019-12-31
--# Ticket # :
--# more comments: this patch must be forced because it impacts the schema of dbschema_fix table
begin work;
alter table dbschema_fix add ( fix_dbsname nchar(48));
update dbschema_fix set fix_dbsname = "kandoodb" where 1=1;
alter table dbschema_fix modify fix_status CHAR(3);
alter table dbschema_fix drop constraint pk_dbschema_fix;
drop index if exists pk_schemafix ;
alter table dbschema_fix add constraint primary key (fix_name,fix_dbsname) constraint pk_dbschema_fix;
alter table dbschema_properties add constraint primary key (dbsname) constraint pk_dbschema_properties;
alter table dbschema_fix add constraint foreign key (fix_dbsname) references dbschema_properties(dbsname) constraint fk_dbschema_fix_dbschema_properties;
insert into dbschema_fix values("20191204-dbschema_x-alttbl","informix","this script adds database name as foreign key in dbschema_fix + creates PK and FK",
"alttbl","","dbschema_fix","04/12/2019","",current,"OK","kandoodb")
commit work;
