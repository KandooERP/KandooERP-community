############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

DEFINE get_debug() boolean
DEFINE pr_menu1 RECORD LIKE menu1.*
#DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.*
#DEFINE glob_rec_kandoouser.cmpy_code LIKE company.cmpy_code
DEFINE pos_cnt, idx INT,
      pr_structure RECORD LIKE structure.*,
      i SMALLINT,
      not_right, start_pos, end_pos SMALLINT,
      chart_start, cnt SMALLINT,
      scrn SMALLINT

DEFINE       pa_structure array[10] of record
         start_num LIKE structure.start_num,
         length_num LIKE structure.length_num,
         desc_text LIKE structure.desc_text,
         flex_code LIKE account.acct_code
      END RECORD
      
DEFINE       pr_validflex RECORD LIKE validflex.*
DEFINE  pr_coa RECORD LIKE coa.*
DEFINE account_code CHAR(18)
            
main

	LET glob_rec_kandoouser.cmpy_code = "01"
	LET account_code ="0000"
	LET get_debug() = TRUE
	
	CALL add_acct_code()
	
   SELECT * INTO pr_coa.* FROM coa
   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
     AND acct_code = account_code

     
        OPEN WINDOW structurewind AT 5,10
      WITH FORM "problemForms/z_huho_foreach_cursor" attribute (border)
      
      IF get_debug() THEN      
      	DISPLAY "##############################"
      	DISPLAY "SELECT * INTO pr_coa.* FROM coa WHERE cmpy_code =", trim(glob_rec_kandoouser.cmpy_code), " AND acct_code = ", trim(account_code)
				DISPLAY "glob_rec_kandoouser.cmpy_code=", glob_rec_kandoouser.cmpy_code
				DISPLAY "account_code=", account_code
				DISPLAY "##############################"
			END IF

      IF get_debug() THEN
      	DISPLAY "#####################################"
      	DISPLAY ".*=", pr_coa
      	DISPLAY "#####################################"
      	
      	DISPLAY "pr_coa.cmpy_code=", trim(pr_coa.cmpy_code)      
      	DISPLAY "pr_coa.acct_code=", trim(pr_coa.acct_code)
      	DISPLAY "pr_coa.desc_text=", trim(pr_coa.desc_text)
      	DISPLAY "pr_coa.start_year_num=", trim(pr_coa.start_year_num)      	
      	DISPLAY "pr_coa.start_period_num=", trim(pr_coa.start_period_num)
      	DISPLAY "pr_coa.end_period_num=", trim(pr_coa.end_period_num)
      	DISPLAY "pr_coa.group_code=", trim(pr_coa.group_code)
      	DISPLAY "pr_coa.uom_code=", trim(pr_coa.uom_code)
      	DISPLAY "pr_coa.type_ind=", trim(pr_coa.type_ind)      	
      END IF

   DECLARE structurecurs CURSOR FOR
      SELECT * INTO pr_structure.* FROM structure
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
         AND start_num > 0
         AND type_ind != "F"
       ORDER BY start_num
   LET pos_cnt = 1
   LET idx = 0
   FOREACH structurecurs
      LET idx = idx + 1
      IF pr_structure.type_ind = "C" THEN
         LET chart_start = pr_structure.start_num
      END IF
      IF get_debug() THEN
      	DISPLAY "#####################################"
      	DISPLAY ".*=", pr_structure
      	DISPLAY "#####################################"
      	
      	DISPLAY "pr_structure.cmpy_code=", trim(pr_structure.cmpy_code)      
      	DISPLAY "pr_structure.start_num=", trim(pr_structure.start_num)
      	DISPLAY "pr_structure.length_num=", trim(pr_structure.length_num)
      	DISPLAY "pr_structure.desc_text=", trim(pr_structure.desc_text)
      	DISPLAY "pr_structure.default_text=", trim(pr_structure.default_text)
      	DISPLAY "pr_structure.type_ind=", trim(pr_structure.type_ind)      	
      END IF
      LET pa_structure[idx].desc_text = pr_structure.desc_text
      LET pa_structure[idx].start_num = pr_structure.start_num
      LET pa_structure[idx].length_num = pr_structure.length_num
      LET pos_cnt = pr_structure.start_num
      LET end_pos = pos_cnt + pr_structure.length_num
      #LET pa_structure[idx].flex_code = account_code[pos_cnt, end_pos-1]
   END FOREACH
   
   END MAIN
   
   
   --01 / 123
   #FUNCTION add_acct_code(glob_rec_kandoouser.cmpy_code, account_code)
   FUNCTION add_acct_code()
#DEFINE glob_rec_kandoouser.cmpy_code LIKE company.cmpy_code
   DEFINE
      account_code CHAR(18),
      msgresp LIKE language.yes_flag,
      pr_coa RECORD LIKE coa.*,
      pr_validflex RECORD LIKE validflex.*,
      pa_structure array[10] of record
         start_num LIKE structure.start_num,
         length_num LIKE structure.length_num,
         desc_text LIKE structure.desc_text,
         flex_code LIKE account.acct_code
      END RECORD,
      pr_structure RECORD LIKE structure.*,
      i, idx SMALLINT,
      not_right, start_pos, end_pos, pos_cnt SMALLINT,
      chart_start, cnt SMALLINT,
      scrn SMALLINT

	LET glob_rec_kandoouser.cmpy_code = "01"
	LET account_code = "123"
	
   WHENEVER ERROR CONTINUE
   OPTIONS DELETE KEY F36,
           INSERT KEY F35
   WHENEVER ERROR STOP
   label next_shot:
# first off check TO see IF the coa IS valid, IF so RETURN
# IF no period OR year_num entered the dont check
   SELECT * INTO pr_coa.* FROM coa
   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
     AND acct_code = account_code
   IF STATUS != NOTFOUND THEN
      LET msgresp = kandoomsg("U",9104,"")
      #9104 RECORD already exists
      LET account_code = "zzzzzzzzzzzzzzzzzz"
      OPTIONS DELETE KEY F2,
              INSERT KEY F1
      RETURN (account_code)
   END IF
# IF problem THEN should we read & DISPLAY the valid flex codes... probably
# also put the account code thru a reformatter which will
# be improved with time....
#LET account_code = reformatter(account_code)
   OPEN WINDOW structurewind AT 5,10
      WITH FORM "G147" attribute (border)
      
      IF get_debug() THEN      
      	DISPLAY "##############################"
				DISPLAY "glob_rec_kandoouser.cmpy_code=", glob_rec_kandoouser.cmpy_code
				DISPLAY "SELECT * INTO pr_structure.* FROM structure WHERE cmpy_code =", trim(glob_rec_kandoouser.cmpy_code),  " AND start_num > 0  AND type_ind != \"F\" ORDER BY start_num "
				DISPLAY "##############################"
			END IF

   DECLARE structurecurs2 CURSOR FOR
      SELECT * INTO pr_structure.* FROM structure
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
         AND start_num > 0
         AND type_ind != "F"
       ORDER BY start_num
   LET pos_cnt = 1
   LET idx = 0
   FOREACH structurecurs2
      LET idx = idx + 1
      IF pr_structure.type_ind = "C" THEN
         LET chart_start = pr_structure.start_num
      END IF
      IF get_debug() THEN
				DISPLAY "pr_structure.* = ", pr_structure.* 
      	DISPLAY "##############################"

      	DISPLAY "pr_structure.cmpy_code=", trim(pr_structure.cmpy_code)      
      	DISPLAY "pr_structure.start_num=", trim(pr_structure.start_num)
      	DISPLAY "pr_structure.length_num=", trim(pr_structure.length_num)
      	DISPLAY "pr_structure.desc_text=", trim(pr_structure.desc_text)
      	DISPLAY "pr_structure.default_text=", trim(pr_structure.default_text)
      	DISPLAY "pr_structure.type_ind=", trim(pr_structure.type_ind)      	
      END IF
      LET pa_structure[idx].desc_text = pr_structure.desc_text
      LET pa_structure[idx].start_num = pr_structure.start_num
      LET pa_structure[idx].length_num = pr_structure.length_num
      LET pos_cnt = pr_structure.start_num
      LET end_pos = pos_cnt + pr_structure.length_num
      LET pa_structure[idx].flex_code = account_code[pos_cnt, end_pos-1]
   END FOREACH
   LET cnt = idx
   CALL set_count(idx)
   LET msgresp = kandoomsg("G",1058,"")
   #1058 F10 Add Flex Code - ESC TO Continue
   INPUT ARRAY pa_structure WITHOUT DEFAULTS FROM sr_structure.*
      
      ON KEY(control-b)
         LET pa_structure[idx].flex_code = show_flex(glob_rec_kandoouser.cmpy_code,
                                                     pa_structure[idx].start_num)
         DISPLAY pa_structure[idx].flex_code TO sr_structure[scrn].flex_code
            
         NEXT FIELD flex_code
      ON KEY(F10)
         CALL run_prog_with_url_arg("GZ4","ARGINT1", l_arr_rec_structure[idx].start_num, "", "", "", "", "", "")
         #CALL run_prog("GZ4",pa_structure[idx].start_num,"","","")
      BEFORE ROW
         LET idx = arr_curr()
         LET scrn = scr_line()
         IF idx <= cnt THEN
            DISPLAY pa_structure[idx].* TO sr_structure[scrn].*
               
         END IF
         IF pa_structure[idx].desc_text IS NULL
         OR pa_structure[idx].start_num < 0 THEN
            EXIT INPUT
         END IF
      AFTER ROW
         DISPLAY pa_structure[idx].* TO sr_structure[scrn].*
            
      AFTER FIELD flex_code
         # Check the individuals AFTER every row
         # FROM validflex AND the complete AT the end
         # FROM the coa
         IF pa_structure[idx].start_num = chart_start THEN
         ELSE
            SELECT * INTO pr_validflex.* FROM validflex
            WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
              AND start_num = pa_structure[idx].start_num
              AND flex_code = pa_structure[idx].flex_code
            IF STATUS = NOTFOUND THEN
               LET msgresp = kandoomsg("U",9105,"")
               #9105 "Record Not Found - Try Window"
               NEXT FIELD flex_code
            END IF
            IF idx <= cnt THEN
               DISPLAY pa_structure[idx].* TO sr_structure[scrn].*
                  
            END IF
         END IF
         IF NOT (fgl_lastkey() = fgl_keyval("accept"))
         AND NOT (fgl_lastkey() = fgl_keyval("up"))
         AND NOT (fgl_lastkey() = fgl_keyval("left"))
         AND (pa_structure[idx+1].desc_text IS NULL
         OR pa_structure[idx+1].start_num < 0) THEN
            LET msgresp = kandoomsg("U",9001,"")
            #9001 No more rows in this direction
            NEXT FIELD flex_code
         END IF
      AFTER INPUT
          IF int_flag OR quit_flag THEN
          ELSE
             LET not_right = 0
             FOR i=1 TO arr_count()
           # Check the individuals AFTER every row
           # FROM validflex AND the complete AT the end
           # FROM the coa
               IF pa_structure[i].start_num = chart_start THEN
               ELSE
                  SELECT * INTO pr_validflex.* FROM validflex
                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
                     AND start_num = pa_structure[i].start_num
                     AND flex_code = pa_structure[i].flex_code
                  IF STATUS = NOTFOUND THEN
                     LET msgresp = kandoomsg("G",9528,i)
                     #9528 Can NOT find flex code on line i
                     LET not_right = 1
                  END IF
               END IF
            END FOR
         END IF
      ON KEY (control-w)
         CALL kandoohelp("")
   END INPUT
     LET idx = arr_curr()
     CLOSE WINDOW structurewind
     IF int_flag OR quit_flag THEN
        LET int_flag = FALSE
        LET quit_flag = FALSE
        LET account_code = "zzzzzzzzzzzzzzzzzz"
        OPTIONS DELETE KEY F2,
                INSERT KEY F1
        RETURN(account_code)
     END IF
     SELECT * INTO pr_structure.* FROM structure
      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
        AND start_num = 0
     LET account_code = pr_structure.default_text
     FOR idx = 1 TO arr_count()
        LET end_pos = pa_structure[idx].start_num
                    + pa_structure[idx].length_num - 1
        LET start_pos = pa_structure[idx].start_num
        LET account_code[start_pos,end_pos] = pa_structure[idx].flex_code
     END FOR
     IF not_right = 1 THEN
        GOTO next_shot
     END IF
     SELECT * INTO pr_coa.* FROM coa
      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
        AND acct_code = account_code
     IF STATUS != NOTFOUND THEN
        LET msgresp = kandoomsg("U",9104,"")
        #9104 RECORD already exists
        LET account_code = "zzzzzzzzzzzzzzzzzz"
        OPTIONS DELETE KEY F2,
                INSERT KEY F1
        RETURN (account_code)
     END IF
     OPTIONS DELETE KEY F2,
             INSERT KEY F1
     RETURN (account_code)
END FUNCTION
   