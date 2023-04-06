--# description: this script cleans the product data and related (all foreign keys)
--# dependencies: 
--# tables list:  category,class,proddept,maingrp,prodgrp,product
--# author: Eric Vercelletto
--# date: 2020-11-02
--# Ticket: 
--# more comments:
delete
from prodledg
where cmpy_code = "99" ;

delete
from ibtdetl
where cmpy_code = "99" ;

delete
from ibthead
where cmpy_code = "99" ;

delete 
from prodstatus
where cmpy_code = "99";

delete
from prodsurcharge
where cmpy_code = "99" ;

delete
from prodinfo
where cmpy_code = "99" ;

delete from product
where cmpy_code = "99";

delete
from prodgrp
where cmpy_code = "99" ;

delete
from maingrp
where cmpy_code = "99" ;

delete
from proddept
where cmpy_code = "99" ;

delete
from category
where cmpy_code = "99" ;

delete 
from class
where cmpy_code = "99" ;
