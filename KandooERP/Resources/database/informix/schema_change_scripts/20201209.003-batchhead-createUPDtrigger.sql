--# description: this script   create a conditional trigger on update "batchhead.post_flag=Y" and calls store procedure doing the check
--# dependencies: 20201209.001-batchhead-dropckconstraint
--# tables list: batchhead 
--# author: eric
--# date: 2020-12-09
--# Ticket # : KD-2499
--# Next step is create the stored procedure 
DROP TRIGGER IF EXISTS upd_batchhead_ck_balance;
CREATE TRIGGER upd_batchhead_ck_balance
UPDATE OF post_flag ON batchhead REFERENCING NEW AS post OLD AS pre
FOR EACH ROW
WHEN (post.post_flag = "Y")
( EXECUTE PROCEDURE batchhead_check_balance(pre.debit_amt,pre.credit_amt,pre.for_debit_amt,pre.for_credit_amt))
