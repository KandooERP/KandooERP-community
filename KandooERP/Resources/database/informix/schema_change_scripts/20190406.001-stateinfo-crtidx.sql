--# description: this script creates a unique index on the stateinfo table
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: stateinfo
--# author: eric vercelletto
--# date: 2019-04-06
--# Ticket # :
--# more comments:
create unique index u_stateinfo on stateinfo(dun_code,cmpy_code);
