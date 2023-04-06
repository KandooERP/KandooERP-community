--# description: this script gives cross database data type consistency  for sign_on_code 
--# tables list: clipboard,grant_deny_access,htmlparms,kandoouser,qxt_log_login,qxt_log_run,userlocn,user_cmpy,userlimits
--# dependencies: 
--# author: ericv
--# date: 2020-09-30
--# Ticket #  	
--# Comments: 
--#
set constraints all deferred;
alter table kandooreport modify (l_entry_code nchar(8));
alter table clipboard modify (sign_on_code nchar(8));
alter table grant_deny_access modify (sign_on_code nchar(8));
alter table htmlparms modify (sign_on_code nchar(8));
alter table kandoouser modify (sign_on_code nchar(8));
alter table qxt_log_login modify (sign_on_code nchar(8));
alter table qxt_log_run modify (sign_on_code nchar(8));
alter table userlocn modify (sign_on_code nchar(8));
alter table user_cmpy modify (sign_on_code nchar(8));
alter table userlimits modify (sign_on_code nchar(8));
set constraints all immediate;
