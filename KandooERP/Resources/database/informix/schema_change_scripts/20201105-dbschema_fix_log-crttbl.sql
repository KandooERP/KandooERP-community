--# description: this script create the dbschema_fix_log and dbschema_fix_errors tables
--# dependencies:
--# tables list:  dbschema_fix_log,dbschema_fix_errors
--# author: Eric Vercelletto
--# date: 2020-11-05
--# Ticket:
--# more comments:
on exception -328 status=OKE;
alter table dbschema_fix add (fix_id integer) ;
on exception -232 status=OKE;
update dbschema_fix set fix_id = rowid where 1 = 1;
alter table dbschema_fix modify (fix_id serial);

create raw table if not exists "informix".dbschema_fix_log
  (
    session_start_ts datetime year to second,
    fix_id integer,
    stmt_order smallint,
    stmt_text lvarchar(512),
    stmt_apply_ts datetime year to second,
    stmt_status char(3),
    error_code integer,
    isam_code integer,
    user_code nchar(8),
    stmt_response_time interval hour to second
  );
create unique index if not exists i_fix_log_session on dbschema_fix_log (session_start_ts,fix_id,stmt_order);

create raw table if not exists dbschema_fix_errors (
    session_start_ts datetime year to second,
    fix_id integer,
    stmt_order smallint,
    error_msg lvarchar(1024)
);
create unique index if not exists i_fix_log_errors on dbschema_fix_errors (session_start_ts,fix_id,stmt_order);
