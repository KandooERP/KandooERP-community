--# description: this script set language_code for AnBl
--# dependencies: none
--# tables list:  language_code
--# author: you
--# date: 2019-04-07
--# Ticket # :
--# more comments:
update kandoouser set language_code = "ENG" where sign_on_code = "AnBl";
