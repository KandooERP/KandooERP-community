#****************************************************************************
#
#           ENSEMBLE DES FONCTIONS COMMUNES A TOUS LES MODULES 
#           (Ne pas oublier d'inclure "p_globals.4gl")
#
# 11 juin 92
#***************************************************************************
#*   SVN URL      : $URL$:
#*   Object       :
#*   SVN Id       : $Id: public_functions.4gl 381 2016-07-30 10:38:15Z  $:
#*   Author       : $Author: $:
#*   Release date : $Date: 2016-07-30 12:38:15 +0200 (sam., 30 juil. 2016) $:
#*   Log          : $Log$:
#***************************************************************************

GLOBALS "p_globals.4gl"
DEFINE version_string char(64)
FUNCTION show_version_module
LET version_string = "@(#)$Id: public_functions.4gl 381 2016-07-30 10:38:15Z  $:"
END FUNCTION

#-----------------------------------------------------------------------------
#    FONCTION :  init_base        a appeler en debut de tous les modules !!
#
#     Fonction d'initialisation de la base
#              - Ouverture de la base
#              - Positionnement des variables globales :
#                transaction   : TRUE si la base supporte les transactions
#                is_ods : TRUE si moteur INFORMIX Online
#                is_ansi     : Si base en mode ANSI 
#
#-----------------------------------------------------------------------------
FUNCTION init_base(dbsname,progname)  

DEFINE i SMALLINT,
progname STRING
DEFINE dbsname STRING
DEFINE qry_txt STRING

WHENEVER ERROR CALL gest_error
 

LET qry_txt = "DATABASE ",dbsname clipped
PREPARE p_openbase FROM qry_txt
EXECUTE p_openbase
IF sqlca.sqlawarn[2] = "W" THEN
   LET is_logged = TRUE
END IF
IF sqlca.sqlawarn[3] = "W" THEN
   LET is_ansi = TRUE
END IF
IF sqlca.sqlawarn[4] = "W" THEN
   LET is_ids = TRUE
END IF

#--- Initialisation du fichier log dans le repertoire $logdir
#    (un fichier par progname)
LET username=fgl_getenv("LOGNAME")
LET screen=fgl_getenv("TTY")
LET logdir=fgl_getenv("LOGDIR")
LET logfile=logdir clipped,"/",progname clipped,".log"

CALL startlog(logfile)

LET show_err  = FALSE      # sans affichage des erreurs (debugging)
LET statut    = 0          # variable globale de gestion des erreurs
LET isamcode = 0          # code derniere erreur ISAM 

#
#  Chargement des parametres du progname
#
FOR i = 1 TO num_args()
    LET parametre[i] = arg_val(i)
END FOR
END FUNCTION

#----------------------------------------------------------------------------
#
# gest_error          GESTION DES ERREURS 
#
#----------------------------------------------------------------------------
FUNCTION gest_error()
DEFINE contexte RECORD
       logname       CHAR(8),
       terminal      CHAR(8),
       text_err      CHAR(80)
END RECORD
DEFINE 4gl_err integer
DEFINE isam_err integer

LET 4gl_err = sqlca.sqlcode
LET isam_err = sqlca.sqlerrd[2]

#--- Seul status est concerne...on ressort
   IF sqlca.sqlcode = 0 THEN
      IF status THEN 
			CALL err_print(status)
			SLEEP 2
      END IF
      RETURN
   END IF

   IF show_err THEN
      DISPLAY "ERROR CODE : ", 4gl_err
      LET contexte.text_err = err_get(4gl_err)
      DISPLAY contexte.text_err
      DISPLAY "ISAM ERROR : ", isam_err
      LET contexte.text_err = err_get(isam_err)
      DISPLAY contexte.text_err
      SLEEP 5
   END IF

#--- Remise a zero automatique du nombre de tentatives
   IF STATUT = 0 THEN
      LET nb_tent = 0
   END IF

#--- Apres 5 appels consecutifs de la fonction d'erreur sans avoir
#    reinitialiser le statut, on passe celui-ci a 9 = ERREUR GRAVE
   IF nb_tent > 5 THEN
      CALL err_print(4gl_err)
      SLEEP 2
      LET statut = 9
   END IF

#--- Si en rentrant dans la fonction d'erreur le statut est 9,
#    on va sortir IMMEDIATEMENT du progname
   IF statut = 9 THEN
      CALL err_print(4gl_err)
      SLEEP 2
      ERROR "********* FATAL ERROR ********* Exiting Program"
      EXIT PROGRAM
   END IF

   WHENEVER ERROR CONTINUE
   #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   # Ici on estampille l'erreur avec le nom de login et terminal
   #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   LET contexte.logname  = fgl_getenv("LOGNAME")
   LET contexte.terminal = fgl_getenv("TTY")
   LET contexte.text_err = " ***** User : ", contexte.logname CLIPPED,
       " - ", contexte.terminal CLIPPED,
       " - Error Code = ", 4gl_err, " / ", isam_err,
       " - Statut = ", statut, " - Nb tent = ", nb_tent
   CALL errorlog(contexte.text_err)
   WHENEVER ERROR STOP

   #*******************************************************************
   # On traitera Quatre principaux types d'erreurs :
   #
   # 1) Les erreurs normales sur enregistrements lockes devant
   #    declencher une boucle de lecture (nb_tent fois)
   #
   # 2) Les erreurs anormales mais connues qui doivent elle
   #    entrainner un arret du traitement en cours
   #
   # 3) Les erreurs qui doivent etre ignorees (comme par exemple
   #    l'erreur -515 sur le "SET ISOLATION" inconnu en moteur
   #    standard
   #
   # 4) Les autres type d'erreurs qui doivent etre obligatoirement
   #    journalisees dans un fichier afin d'etre traitees ulterieurement
   #*******************************************************************

   CASE 4gl_err

   #-----------------#
   # ERREURS  TYPE 1 #
   #-----------------#
   WHEN -233
      # "Could not read record locked by another"
         LET statut = 1
         LET nb_tent = nb_tent + 1

   WHEN -244
      # "Could not do a physical-order read to fetch next row"
         LET statut = 1
         LET nb_tent = nb_tent + 1


   WHEN -246
      # "Could not do an indexed read to get next row"
      # (ou table lockee en "share mode")
           LET statut = 1
         LET nb_tent = nb_tent + 1

   WHEN -259
      # "Cursor not open"
           LET statut = 1
         LET nb_tent = nb_tent + 1

   WHEN -250
      # "Cannot read record from file for update"
      # (Moteur stanndard)
           LET statut = 1
         LET nb_tent = nb_tent + 1

   WHEN -263
      # "Could not lock row for UPDATE"
           LET statut = 1
         LET nb_tent = nb_tent + 1

   WHEN -266
      # "There is no current row for UPDATE/DELETE cursor"
           LET statut = 1
         LET nb_tent = nb_tent + 1

   WHEN -346
      # "Could not update a row in the table"
           LET statut = 1
         LET nb_tent = nb_tent + 1

   #-----------------#
   # ERREURS  TYPE 2 #
   #-----------------#
   WHEN -245
      # "Could not position within a file via an index"
           LET statut = 1
         LET nb_tent = nb_tent + 1

   WHEN -271
      # "Could not insert new row into the table"
	 	LET statut = 2
		LET nb_tent = nb_tent + 1

	WHEN -239
		# could not insert new row - duplicate value
		LET statut = 2
      LET nb_tent = nb_tent + 1

	WHEN -268
		# unique constraint ... violated
		LET statut = 2
      LET nb_tent = nb_tent + 1

	WHEN -284
		# A subquery has returned not exactly one row
		LET statut = 2
      LET nb_tent = nb_tent + 1

	WHEN -690
		# cannot read keys from referencing table ...
		LET statut = 2
      LET nb_tent = nb_tent + 1

	WHEN -691
		# missing key in referenced table for constraint ...
		LET statut = 2
      LET nb_tent = nb_tent + 1

	WHEN -692
		# key value for constraint ... is still referenced
		LET statut = 2
      LET nb_tent = nb_tent + 1

   WHEN -407
      # "Error number zero received from the sqlexec process"
      LET statut = 2
      LET nb_tent = nb_tent + 1

   WHEN -408
      # "Invalid message received from the sqlexec process"
           LET statut = 9
         LET nb_tent = nb_tent + 1

   WHEN -458
      # long transaction aborted
      LET statut = 9
      LET nb_tent = nb_tent + 1


   #-----------------#
   # ERREURS  TYPE 3 #
   #-----------------#
   WHEN -256
      #"Transactions not available"
      LET statut = 0

   WHEN -535
      # Already in Transactions
      LET statut = 0


   #-----------------#
   # ERREURS  TYPE 4 #
   #-----------------#
   OTHERWISE
      CALL err_print(4gl_err)
      SLEEP 2
      LET statut = 9
   END CASE
   #--------------------------------------------------------------

END FUNCTION

######################################################################
# Function choose_printer()  # Affiche les imprimantes pour selection#
######################################################################
FUNCTION choose_printer(ligne,colonne)        #lecture des imprimante#
define lig smallint,cnt ,scrlin,arcur,ligne,colonne smallint,
cprel char(4),

w_imprimante array[20] of record
   libel like imprimante.libel
end record,

n_imprimante record
   libel like imprimante.libel
end record,

n_retour record
   code like imprimante.code,
   tcap  like imprimante.tcap,
   uprop like imprimante.uprop,
   instruction like imprimante.instruction,
   init like imprimante.init,
   portrait like imprimante.portrait,
   paysage like imprimante.paysage,
   gras like imprimante.gras,
   fingras like imprimante.fingras
end record,

w_retour array[20] of record
   code like imprimante.code,
   tcap  like imprimante.tcap,
   uprop like imprimante.uprop,
   instruction like imprimante.instruction,
   init like imprimante.init,
   portrait like imprimante.portrait,
   paysage like imprimante.paysage,
   gras like imprimante.gras,
   fingras like imprimante.fingras
end record
INITIALIZE n_retour.* TO null
INITIALIZE n_imprimante.* TO null
open window imprime at ligne,colonne
with form "w_impr" attribute (border)

FOR cnt = 1 to 20
    LET w_imprimante[cnt].*=n_imprimante.*
    LET w_retour[cnt].*=n_retour.*
END FOR

DECLARE cursp CURSOR FOR
SELECT i.libel,i.code,i.tcap,i.uprop,i.instruction,
i.init,i.portrait,i.paysage,i.gras,i.fingras
FROM imprimante i
let cnt=1
DISPLAY "** LISTE DES IMPRIMANTES **" at 2,4 attribute(reverse)
FOREACH cursp INTO w_imprimante[cnt].libel,w_retour[cnt].*
    let cnt=cnt+1
    IF cnt > 20 THEN
       EXIT FOREACH
    END IF
END FOREACH

call set_count(cnt-1)
WHILE true
   INPUT ARRAY w_imprimante WITHOUT DEFAULTS
   FROM e_impr.*
   BEFORE ROW  
      let scrlin=scr_line()
      let arcur=arr_curr()
      DISPLAY w_imprimante[arcur].* TO e_impr[scrlin].* attribute(reverse)
   AFTER ROW  
      let scrlin=scr_line()
      let arcur=arr_curr()
      DISPLAY w_imprimante[arcur].* TO e_impr[scrlin].* attribute(normal)
      IF arcur >= cnt THEN
         error "vous avez depasse la derniere imprimante"
         CONTINUE WHILE
      END IF
   END INPUT
   IF fgl_lastkey()=fgl_keyval("return") THEN
      EXIT WHILE
   END IF
END WHILE

CLOSE WINDOW imprime
IF not int_flag THEN
   let libelimp = w_imprimante[arcur].libel
   let codimp   = w_retour[arcur].code
   let tcapimp  = w_retour[arcur].tcap
   let comimp   = w_retour[arcur].instruction
   let gras = w_retour[arcur].gras
   let fingras = w_retour[arcur].fingras
   let upri = w_retour[arcur].uprop clipped
   let initpr = w_retour[arcur].init clipped
   let portrait = w_retour[arcur].portrait clipped
   let paysage = w_retour[arcur].paysage clipped
ELSE
   LET int_flag=false
END IF
END FUNCTION

