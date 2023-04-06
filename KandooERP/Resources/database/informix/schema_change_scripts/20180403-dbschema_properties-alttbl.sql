--# description: this script alters the table dbschema_fix to keep last patch successful and failed scripts numbers
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  dbschema_fix
--# author: eric vercelletto
--# date: 2019-04-03
--# Ticket # :
--# more comments:
alter table dbschema_properties add (build_id char(32),last_patch_ok_scripts smallint,last_patch_ko_scripts smallint);
