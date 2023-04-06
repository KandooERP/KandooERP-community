{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	Source code beautified by beautify.pl on 2020-01-03 18:54:41	$Id: $
}



#     U18a.4gl  Contains table/COLUMN lookup facility
#               This module IS stand alone AND IS able TO provide lookup
#               TO other programs by linking in this module
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

GLOBALS 
	DEFINE pr_tabext_ind SMALLINT 
	DEFINE pr_colext_ind SMALLINT 
	DEFINE pr_sql_text CHAR(256)## this IS a scratch variable used TO comminicate 
	## between functions. Made global TO avoid passing
	## large string variables beween functions.
END GLOBALS 


FUNCTION show_tables() 
	DEFINE 
	pr_systables RECORD # DEFINE COLUMNS as RECORD depends ON engine 
		tabname CHAR (128), 
		tabtype CHAR(1), 
		tabid INTEGER, 
		owner CHAR(32), 
		ncols SMALLINT, 
		rowsize SMALLINT, 
		nrows INTEGER, 
		nindexes SMALLINT 
	END RECORD, 
	pa_systables array[512] OF RECORD 
		tag_ind CHAR(1), 
		tabname CHAR (128), 
		tabtype CHAR(1), 
		tabid INTEGER, 
		owner CHAR(32), 
		ncols SMALLINT, 
		rowsize SMALLINT, 
		nrows INTEGER, 
		nindexes SMALLINT 
	END RECORD, 
	where_text CHAR(128), 
	query_text CHAR(256), 
	pr_table_text CHAR(100), 
	idx,scrn SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	SELECT count(*) INTO pr_tabext_ind FROM systables 
	WHERE tabname = "systableext" 
	SELECT count(*) INTO pr_colext_ind FROM systables 
	WHERE tabname = "syscolumnext" 

	OPEN WINDOW u143 at 3,4 with FORM "U143" 
	CALL windecoration_u("U143") 

	OPTIONS INPUT no wrap 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("U",1001,"") 
		#U 1001 " Enter Selection Criteria, ESC TO Continue"
		CONSTRUCT BY NAME where_text ON tabname, 
		tabtype, 
		tabid, 
		owner, 
		ncols, 
		rowsize, 
		nrows, 
		nindexes 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U18a","construct-systables") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET l_msgresp=kandoomsg("U",1005,"") 
		#U 1005 " Please wait!"
		LET query_text = 
		"SELECT tabname,tabtype,tabid,owner,ncols,rowsize,nrows,nindexes ", 
		"FROM systables ", 
		"WHERE ",where_text clipped," ", 
		"ORDER BY 1" 
		PREPARE s_systables FROM query_text 
		DECLARE c_systables CURSOR FOR s_systables 
		LET idx = 0 
		FOREACH c_systables INTO pr_systables.* 
			LET idx = idx + 1 
			LET pa_systables[idx].tag_ind = " " 
			LET pa_systables[idx].tabname = pr_systables.tabname 
			LET pa_systables[idx].tabtype = pr_systables.tabtype 
			LET pa_systables[idx].tabid = pr_systables.tabid 
			LET pa_systables[idx].owner = pr_systables.owner 
			LET pa_systables[idx].ncols = pr_systables.ncols 
			LET pa_systables[idx].rowsize = pr_systables.rowsize 
			LET pa_systables[idx].nrows = pr_systables.nrows 
			LET pa_systables[idx].nindexes = pr_systables.nindexes 
			IF idx = 512 THEN 
				LET l_msgresp=kandoomsg("U",9014,idx) 
				#9014  Only first 512 tables displayed !"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		CLOSE c_systables 
		IF idx = 0 THEN 
			LET l_msgresp=kandoomsg("U",9017,"") 
			#9017 No tables can be found matching entered criteria"
		ELSE 
			LET l_msgresp=kandoomsg("U",1014,idx) 
			# U 1014 ENTER FOR details, F8 TO tag, ESC TO resume"
			CALL set_count(idx) 
			DISPLAY ARRAY pa_systables TO sr_systables.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","U18a","display-arr-systables") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (tab) 
					LET idx = arr_curr() 
					IF disp_table(pa_systables[idx].tabid, 
					pa_systables[idx].tabname) THEN 
						EXIT DISPLAY 
					END IF 
				ON KEY (RETURN) 
					LET idx = arr_curr() 
					IF disp_table(pa_systables[idx].tabid, 
					pa_systables[idx].tabname) THEN 
						EXIT DISPLAY 
					END IF 
				ON KEY (F8) 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					IF pa_systables[idx].tag_ind != "*" THEN 
						LET pa_systables[idx].tag_ind = "*" 
					ELSE 
						LET pa_systables[idx].tag_ind = " " 
					END IF 
					DISPLAY pa_systables[idx].tag_ind TO sr_systables[scrn].tag_ind 

				ON KEY (control-w) 
					CALL kandoohelp("") 
			END DISPLAY 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW u143 
	OPTIONS INPUT wrap 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		FOR idx = 1 TO arr_count() 
			IF pa_systables[idx].tag_ind = "*" THEN 
				IF length(pr_table_text) + length(pr_sql_text) > 250 THEN 
					LET l_msgresp=kandoomsg("U",9018,"") 
					#9018" Maximum selection size has been exceeded"
					EXIT FOR 
				END IF 
				IF pr_table_text IS NULL THEN 
					LET pr_table_text = pa_systables[idx].tabname 
				ELSE 
					LET pr_table_text = pr_table_text clipped,",", 
					pa_systables[idx].tabname 
				END IF 
			END IF 
		END FOR 
		IF pr_table_text IS NOT NULL THEN 
			IF pr_sql_text IS NOT NULL THEN 
				LET pr_sql_text = pr_sql_text clipped," FROM ",pr_table_text clipped 
			ELSE 
				LET pr_sql_text = pr_table_text clipped 
			END IF 
		END IF 
		RETURN pr_sql_text 
	END IF 
END FUNCTION 


FUNCTION disp_table(pr_tabid,pr_tabname) 
	DEFINE 
	pr_tabid INTEGER, 
	pr_tabname CHAR (128), 
	pr_syscolumns RECORD # DEFINE COLUMNS as RECORD depends ON engine 
		tabid INTEGER, 
		colno SMALLINT, 
		colname CHAR(128), 
		coltype SMALLINT, 
		collength SMALLINT 
	END RECORD, 
	pa_syscolumns array[256] OF RECORD 
		tag_ind CHAR(1), 
		colname CHAR (128), 
		datatype CHAR(25) 
	END RECORD, 
	idx,scrn SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW u144 at 2,20 with FORM "U144" 
	CALL windecoration_u("U144") 

	LET pr_sql_text = NULL 
	LET l_msgresp=kandoomsg("U",1005,"") 
	#U 1005 " Please wait!"
	DISPLAY pr_tabname TO tabname 

	DECLARE c_syscolumns CURSOR FOR 
	SELECT tabid,colno,colname,coltype,collength 
	FROM syscolumns WHERE tabid = pr_tabid 
	ORDER BY colno 
	LET idx = 0 
	FOREACH c_syscolumns INTO pr_syscolumns.* 
		LET idx = idx + 1 
		LET pa_syscolumns[idx].tag_ind = " " 
		LET pa_syscolumns[idx].colname = pr_syscolumns.colname 
		LET pa_syscolumns[idx].datatype = 
		column_defintion(pr_syscolumns.coltype,pr_syscolumns.collength) 
		IF idx <= 14 THEN # change value TO match LINES ON screen 
			DISPLAY pa_syscolumns[idx].* 
			TO sr_syscolumns[idx].* 

		END IF 
		IF idx = 256 THEN 
			LET l_msgresp=kandoomsg("U",9015,idx) 
			#9015  Only first 256 columns displayed !"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CLOSE c_syscolumns 
	MENU "TABLE" 
		BEFORE MENU 
			SELECT unique 1 FROM systables 
			WHERE tabid = pr_tabid 
			AND ncols = 0 
			IF status = 0 THEN 
				HIDE option "Columns" 
			END IF 
			SELECT unique 1 FROM systables 
			WHERE tabid = pr_tabid 
			AND nindexes = 0 
			IF status = 0 THEN 
				HIDE option "Indexes" 
			END IF 
			HIDE option "Resume" 

			CALL publish_toolbar("kandoo","U18a","menu-table") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Columns" "View COLUMN details" 
			LET l_msgresp=kandoomsg("U",1015,idx) 
			# U 1015 ENTER FOR details, F8 TO tag, ESC TO resume"
			CALL set_count(idx) 
			DISPLAY ARRAY pa_syscolumns TO sr_syscolumns.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","U18a","display-arr-syscolumns") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (tab) 
					LET idx = arr_curr() 
					CALL describe_column(pr_tabname, 
					pa_syscolumns[idx].colname, 
					pa_syscolumns[idx].datatype) 
				ON KEY (F8) 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					IF pa_syscolumns[idx].tag_ind != "*" THEN 
						LET pa_syscolumns[idx].tag_ind = "*" 
					ELSE 
						LET pa_syscolumns[idx].tag_ind = " " 
					END IF 
					DISPLAY pa_syscolumns[idx].tag_ind TO sr_syscolumns[scrn].tag_ind 

				ON KEY (control-w) 
					CALL kandoohelp("") 
			END DISPLAY 
			SHOW option "Resume" 
		COMMAND "Indexes" "View index details" 
			CALL show_indexes(pr_tabid,pr_tabname) 
		COMMAND "Description" "View table description" 
			CALL describe_table(pr_tabid) 
		COMMAND KEY ("R",accept) "Resume" 
			" RETURN TO list of tables (with selections)" 
			FOR idx = 1 TO arr_count() 
				IF pa_syscolumns[idx].tag_ind = "*" THEN 
					IF length(pr_sql_text) > 250 THEN 
						LET l_msgresp=kandoomsg("U",9018,"") 
						#9018" Maximum selection size has been exceeded"
						EXIT FOR 
					END IF 
					IF pr_sql_text IS NULL THEN 
						LET pr_sql_text = pa_syscolumns[idx].colname 
					ELSE 
						LET pr_sql_text = pr_sql_text clipped,",", 
						pa_syscolumns[idx].colname 
					END IF 
				END IF 
			END FOR 
			EXIT MENU 
		COMMAND KEY("E",interrupt)"Exit" 
			" RETURN TO list of tables (without selections)" 
			LET quit_flag = true 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW u144 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION show_indexes(pr_tabid,pr_tabname) 
	DEFINE 

	pr_syscolumns RECORD # DEFINE COLUMNS as RECORD depends ON engine 
		tabid INTEGER, 
		colno SMALLINT, 
		colname CHAR(128), 
		coltype SMALLINT, 
		collength SMALLINT 
	END RECORD, 
	pa_syscolumns array[256] OF RECORD 
		tag_ind CHAR(1), 
		colname CHAR (128), 
		datatype CHAR(25) 
	END RECORD, 
	pr_tabid INTEGER, 
	pr_tabname CHAR(128), 
	pa_sysidx array[25] OF RECORD 
		idxname CHAR(128), 
		idxtype CHAR(1), 
		clustered CHAR(1), 
		colname_a CHAR(128), 
		colname_b CHAR(128), 
		colname_c CHAR(128), 
		colname_d CHAR(128), 
		colname_e CHAR(128), 
		colname_f CHAR(128), 
		colname_g CHAR(128), 
		colname_h CHAR(128) 
	END RECORD, 
	pr_sysidx RECORD #like sysindexes.*, 
		idxname CHAR(128), 
		owner CHAR(32), 
		tabid INTEGER, 
		idxtype CHAR(1), 
		clustered CHAR(1), 
		part1 SMALLINT, 
		part2 SMALLINT, 
		part3 SMALLINT, 
		part4 SMALLINT, 
		part5 SMALLINT, 
		part6 SMALLINT, 
		part7 SMALLINT, 
		part8 SMALLINT, 
		part9 SMALLINT, 
		part10 SMALLINT, 
		part11 SMALLINT, 
		part12 SMALLINT, 
		part13 SMALLINT, 
		part14 SMALLINT, 
		part15 SMALLINT, 
		part16 SMALLINT, 
		levels SMALLINT, 
		leaves INTEGER, 
		nunique INTEGER, 
		clust INTEGER 
	END RECORD, 
	x, i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW u501 at 5,5 with FORM "U501" 
	CALL windecoration_u("U501") 

	LET l_msgresp=kandoomsg("U",1005,"") 
	#U 1005 " Please wait!"
	DISPLAY pr_tabname TO tabname 

	DECLARE i_curs CURSOR FOR 
	SELECT * FROM sysindexes 
	WHERE tabid = pr_tabid 
	ORDER BY idxname 
	LET i = 0 
	FOREACH i_curs INTO pr_sysidx.* 
		LET i = i + 1 
		LET pa_sysidx[i].idxname = pr_sysidx.idxname 
		LET pa_sysidx[i].idxtype = pr_sysidx.idxtype 
		LET pa_sysidx[i].clustered = pr_sysidx.clustered 
		IF pr_sysidx.part1 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_a 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part1 
		END IF 
		IF pr_sysidx.part2 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_b 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part2 
		END IF 
		IF pr_sysidx.part3 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_c 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part3 
		END IF 
		IF pr_sysidx.part4 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_d 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part4 
		END IF 
		IF pr_sysidx.part5 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_e 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part5 
		END IF 
		IF pr_sysidx.part6 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_f 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part6 
		END IF 
		IF pr_sysidx.part7 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_g 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part7 
		END IF 
		IF pr_sysidx.part8 > 0 THEN 
			SELECT colname INTO pa_sysidx[i].colname_h 
			FROM syscolumns 
			WHERE tabid = pr_tabid 
			AND colno = pr_sysidx.part8 
		END IF 
		IF i = 25 THEN 
			LET l_msgresp=kandoomsg("U",9016,i) 
			#9016 "Only first 25 indexes displayed !"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp=kandoomsg("U",1016,i) 
	# U 1016 ESC TO resume"
	CALL set_count(i) 
	DISPLAY ARRAY pa_sysidx TO sr_sysidx.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","U18a","display-arr-sysidx") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW u501 
END FUNCTION 


FUNCTION describe_table(pr_tabid) 
	DEFINE 
	pr_tabid INTEGER, 
	pr_systableext RECORD # i-dba extended TABLE (may NOT exist) 
		owner CHAR(32), 
		tabname CHAR(32), 
		extowner CHAR(32), 
		tabalias CHAR(32), 
		remarks CHAR(256) 
	END RECORD 

	INITIALIZE pr_systableext.tabname TO NULL 
	IF pr_tabext_ind THEN 
		SELECT systableext.* INTO pr_systableext.* 
		FROM systableext, 
		systables 
		WHERE systables.tabid = pr_tabid 
		AND systableext.tabname = systables.tabname 
	END IF 
	OPEN WINDOW u503 at 4,10 with FORM "U503" 
	CALL windecoration_u("U503") 

	DISPLAY BY NAME pr_systableext.tabname, 
	pr_systableext.tabalias, 
	pr_systableext.remarks 

	CALL eventsuspend() # LET l_msgresp=kandoomsg("U",1,"") 
	CLOSE WINDOW u503 
END FUNCTION 


FUNCTION describe_column(pr_tabname,pr_colname,pr_datatype) 
	DEFINE 
	pr_tabname CHAR(128), 
	pr_colname CHAR(128), 
	pr_datatype CHAR(25), 
	pr_syscolumnext RECORD # i-dba extended TABLE (may NOT exist) 
		owner CHAR(32), 
		tabname CHAR(32), 
		colname CHAR(32), 
		extowner CHAR(32), 
		colalias CHAR(32), 
		collabel CHAR(32), 
		coltitle CHAR(32), 
		remarks CHAR(256), 
		subtype CHAR(4), 
		class CHAR(32) 
	END RECORD, 
	m SMALLINT, 
	pr_kandooword RECORD LIKE kandooword.*, 
	pa_kandooword array[100] OF RECORD #list OF possible VALUES 
		reference_code LIKE kandooword.reference_code, 
		response_text LIKE kandooword.response_text 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	
	INITIALIZE pr_syscolumnext.* TO NULL 
	IF pr_colext_ind THEN 
		SELECT syscolumnext.* INTO pr_syscolumnext.* 
		FROM syscolumnext 
		WHERE systables.tabid = pr_tabid 
		AND syscolumnext.tabname = pr_tabname 
		AND syscolumnext.colname = pr_colname 
	END IF 

	OPEN WINDOW u504 at 2,3 with FORM "U504" 
	CALL windecoration_u("U504") 

	LET pr_kandooword.reference_text = pr_tabname clipped, 
	".", 
	pr_colname clipped 
	DISPLAY BY NAME pr_kandooword.reference_text, 
	pr_syscolumnext.colalias, 
	pr_syscolumnext.remarks, 
	pr_syscolumnext.collabel, 
	pr_syscolumnext.coltitle 

	DISPLAY pr_datatype TO datatype 

	DECLARE m_curs CURSOR FOR 
	SELECT * FROM kandooword 
	WHERE language_code = "ENG" 
	AND reference_text = pr_kandooword.reference_text 
	ORDER BY reference_code 
	LET m = 0 
	FOREACH m_curs INTO pr_kandooword.* 
		LET m = m + 1 
		LET pa_kandooword[m].reference_code = pr_kandooword.reference_code 
		LET pa_kandooword[m].response_text = pr_kandooword.response_text 
		IF m = 100 THEN 
			LET l_msgresp=kandoomsg("U",9016,m) 
			#9016 "Only first i entries displayed !"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(m) 
	DISPLAY ARRAY pa_kandooword TO sr_kandooword.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","U18a","display-arr-kandooword") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END DISPLAY 


	CLOSE WINDOW u504 
END FUNCTION 


