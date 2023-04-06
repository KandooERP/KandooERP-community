--# description: this script creates foreign key for prodgrp table to maingrp
--# tables list: prodgrp,maingrp
--# author: ericv
--# date: 2020-09-28
--# track bad rows with the following query
--# select maingrp_code||cmpy_code from prodgrp where maingrp_code||cmpy_code not in ( select maingrp_code||cmpy_code from maingrp );
alter table prodgrp add constraint foreign key (maingrp_code,dept_code,cmpy_code) references maingrp (maingrp_code,dept_code,cmpy_code) constraint fk_prodgrp_maingrp;	
