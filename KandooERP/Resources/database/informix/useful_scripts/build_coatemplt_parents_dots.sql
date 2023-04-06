-- this scripts sets the acct_code tree level and parentid
-- when separator is . - etc, tree_level = count_char + 1
update coatempltdetl
set 
parent = get_parentid(acct_code,"."),
tree_level = count_char(acct_code,".") + 1
where 1=1
and country_code = "IFR"
;
select acct_code,tree_level,parent
from coatempltdetl
where 1=1
and country_code = "IFR"
--and acct_code matches "*.*"
order by 1

