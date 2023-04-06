--# description: this script creates a 1 to many relationship from kandoousercmpy to kandoouser
--# dependencies: n/a
--# tables list: kandoouser,kandoousercmpy
--# author: ericv
--# date: 2020-05-30
--# Ticket # : 
--# Comments: check integrity with the following query
--# select sign_on_code||cmpy_code from kandoousercmpy where sign_on_code||cmpy_code not in (select sign_on_code||cmpy_code from kandoouser)
drop  index if exists u_kandoousercmpy ;
create unique index u_kandoousercmpy on kandoousercmpy (sign_on_code, cmpy_code);
ALTER TABLE kandoousercmpy ADD CONSTRAINT FOREIGN KEY (sign_on_code, cmpy_code) references kandoouser (sign_on_code, cmpy_code) CONSTRAINT fk_kandoousercmpy_kandoouser;
