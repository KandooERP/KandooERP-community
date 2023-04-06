-- this scripts sets the acct_code tree level and parentid
-- when NO separator , tree_level = count_char
update coatempltdetl
set 
parent = get_parentid(acct_code,"*"),
tree_level = count_char(acct_code,"*")
where 1=1
and country_code = "FR"
;
select acct_code,tree_level,parent
from coatempltdetl
where 1=1
and country_code = "FR"
--and acct_code matches "*.*"
order by 1

