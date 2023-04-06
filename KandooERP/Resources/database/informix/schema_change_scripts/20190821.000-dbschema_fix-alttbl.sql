--# description: this script change fix_apply_date to timestamp
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: dbschema_fix
--# author: Eric Vercelletto
--# date: 2019-08-21
--# Ticket # :
--# more comments:
drop index "informix".pk_schemafix ;
create unique index "informix".pk_schemafix on "informix".dbschema_fix (fix_name,fix_status) using btree ;
alter table dbschema_fix modify fix_apply_date datetime year to second;
