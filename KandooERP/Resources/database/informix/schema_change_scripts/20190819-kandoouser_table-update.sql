--# description:  this script modifies the table kandoouser
--# dependencies: none
--# tables list:  kandoouser
--# author: Alex Bondar
--# date: 2019-08-19
--# Ticket # :
--# more comments: first backup the existing contents (unload to xxx.bkp), then update kandoouser table.

--unload to "unl/kandoouser.bkp" select * from kandoouser;
begin work;
delete from kandoouser where sign_on_code = "GuGo";
--insert into kandoouser values ("GuGo","Gustavo González","N","GuGo","ESP","MA","????","MAX","1","19/08/2019","PRINT-DEVICE-01",0,0,"1",null,"1","1","g.gonzalez@kandooerp.org","GuGo","U","1",null,null,0);
update kandoouser set language_code  = "FRA" where sign_on_code = "ErVe";
update kandoouser set user_role_code = "U",security_ind = "N" where 1=1;
update kandoouser set user_role_code = "A",security_ind = "Z" where sign_on_code in ("Admin","HuHo","ErVe","AlBo","AlCh","AnBl","GeTh");
update kandoouser set user_role_code = "S",security_ind = "X" where sign_on_code in ("MeAf","AlAf","AlPr","SpWh");
commit work;
