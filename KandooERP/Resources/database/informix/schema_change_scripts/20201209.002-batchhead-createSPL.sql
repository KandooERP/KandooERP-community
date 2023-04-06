--# description: this script creates a stored procedure that checks balance of a batch in batchdetl and compares sums with batchhead  
--# dependencies: 
--# tables list: batchhead 
--# author: eric
--# date: 2020-12-09
--# Ticket # : KD-2499
--#  20201209.001-batchhead-dropckconstraint

drop procedure if exists batchhead_batchdetl_check_balance;
create procedure batchhead_batchdetl_check_balance(p_cmpy_code NCHAR(2),p_jour_code CHAR(2),p_jour_num INTEGER) ;
DEFINE l_balance MONEY(16,2);
DEFINE l_credit_sum MONEY(16,2);
DEFINE l_debit_sum MONEY(16,2);
DEFINE l_for_credit_sum MONEY(16,2);
DEFINE l_for_debit_sum MONEY(16,2);
DEFINE l_head_credit MONEY(16,2);
DEFINE l_head_debit MONEY(16,2);
DEFINE l_head_for_credit MONEY(16,2);
DEFINE l_head_for_debit MONEY(16,2);
SET DEBUG FILE TO "/tmp/balance_check.log";
TRACE ON;
-- select sums of debit and credit for the whole batch
select sum(debit_amt),sum(credit_amt),sum(for_debit_amt),sum(for_credit_amt)
INTO l_debit_sum,l_credit_sum,l_for_debit_sum,l_for_credit_sum
from batchdetl
where cmpy_code = p_cmpy_code
and jour_code = p_jour_code
AND jour_num = p_jour_num;
if (l_debit_sum IS NULL OR l_credit_sum IS NULL OR l_for_debit_sum IS NULL OR l_for_credit_sum IS NULL ) then
   RAISE EXCEPTION -746, 0, 'batchhead has no batchdetl entries' ;
end if;
if (l_debit_sum <> l_credit_sum) OR (l_for_debit_sum <> l_for_credit_sum ) then
   RAISE EXCEPTION -746, 0, 'sums of debit <> sums of credit ';
end if;
-- compare batchdetl sums with batchhead figgures
select debit_amt,credit_amt,for_debit_amt,for_credit_amt
INTO l_head_debit,l_head_credit,l_head_for_debit,l_head_for_credit
from batchhead
where cmpy_code = p_cmpy_code
and jour_code = p_jour_code
AND jour_num = p_jour_num;
if (l_debit_sum <> l_head_debit OR l_credit_sum <> l_head_credit OR l_for_debit_sum <> l_head_for_debit OR l_for_credit_sum <> l_head_for_credit ) THEN
   RAISE EXCEPTION -746, 0, 'sums from detl <> sums from head ';
end if;

END PROCEDURE;
