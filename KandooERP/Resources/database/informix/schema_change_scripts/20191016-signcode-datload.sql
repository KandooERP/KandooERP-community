--# description: This script populates the 'signcode' table with data
--# tables list: signcode
--# author: albo
--# date: 2019-10-16
--# Ticket # : 	
--# more comments:

begin work;
delete from signcode where 1=1;
INSERT INTO signcode VALUES('Y','Reverse all database signs','Y','');
INSERT INTO signcode VALUES('N','Leave database signs unchanged','N','');
INSERT INTO signcode VALUES('+','Change all database signs to +','Y','+');
INSERT INTO signcode VALUES('-','Change all database signs to -','Y','-'); 
commit work;

