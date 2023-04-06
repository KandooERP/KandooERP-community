--# description: this script creates roles for security
--# dependencies: 
--# tables list: all
--# author: ericv
--# date: 2020-05-18
--# Ticket # : 
create role allmodules_user;
create role allmodules_admin;
create role kandoo_sysadmin;
create role ar_admin;
create role ar_user;
create role eo_admin;
create role eo_user;
create role fa_admin;
create role fa_user;
create role gl_admin;
create role gl_user;
create role in_admin;
create role in_user;
create role jm_admin;
create role jm_user;
create role ss_admin;
create role ss_user;
create role lc_admin;
create role lc_user;
create role re_admin;
create role re_user;
create role ap_admin;
create role ap_user;
create role qe_admin;
create role qe_user;
create role pu_admin;
create role pu_user;
create role ut_admin;
create role ut_user;
grant default role allmodules_user to kandooer;
grant default role allmodules_admin to kandooappadm;
