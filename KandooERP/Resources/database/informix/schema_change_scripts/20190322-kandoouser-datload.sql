--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: kandoouser
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/kandoouser.unl SELECT * FROM kandoouser;
drop table kandoouser;

create table "informix".kandoouser 
(
sign_on_code nvarchar(8),
name_text nvarchar(80),
security_ind nchar(1),
password_text nvarchar(80),
language_code nchar(3),
cmpy_code char(2),
acct_mask_code char(18),
profile_code nchar(3),
access_ind nchar(1),
sign_on_date date,
print_text nvarchar(20),
act_spawn_num smallint,
max_spawn_num smallint,
group_code nchar(1),  /* missleading - is used for cheque and user group */
signature_text nvarchar(20),
passwd_ind nchar(1),
memo_pri_ind nchar(1),
email nvarchar(80),
login_name nvarchar(80),  /*new login name for authentication */
user_role_code nchar(1),  /*for future*/
menu_group_code nchar(1),  /*currently used for qxt menu*/
cheque_group_code nchar(1),  /*kandoo uses some cheque_group_code which uses hte missleading columnname group_code ... and .. for later..*/
pwChDate date,
pwChange int   /*0=no change required 1=change required */

);

LOAD FROM unl20190322/kandoouser.unl INSERT INTO kandoouser;
