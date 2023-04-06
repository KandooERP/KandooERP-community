--# description:  this script insert data for default-templated company number '99'
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: kandoooption
--# author: albo
--# date: 2019-09-16
--# Ticket # :
--# more comments: Table kandoooption must always have following rows PRIOR TO SETTING UP ANYTHING (out of the box)

begin work;
delete from kandoooption where cmpy_code = "99";
load from unl/20190916-kandoooption.unl insert into kandoooption;
commit work;

