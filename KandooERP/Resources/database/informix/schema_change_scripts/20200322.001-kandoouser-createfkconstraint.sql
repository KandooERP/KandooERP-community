--# description: this script creates a foreign key constraint from kandoouser to language
--# dependencies: n/a
--# tables list: kandoouser
--# author: ericv
--# date: 2020-03-22
--# Ticket # : 
--# 
create index d01_kandoouser on kandoouser (language_code) using btree;
ALTER TABLE kandoouser ADD CONSTRAINT FOREIGN KEY (language_code) references language CONSTRAINT fk_kandoouser_language;
