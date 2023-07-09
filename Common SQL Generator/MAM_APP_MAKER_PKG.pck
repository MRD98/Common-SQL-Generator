CREATE OR REPLACE PACKAGE MAM_APP_MAKER_PKG IS
  FUNCTION MAM_PACK_INPUT_FUN(P_INPUT         VARCHAR2
                             ,P_RESULT_LENGTH INT) RETURN VARCHAR2;
  FUNCTION CREATE_APP_PACKAGE_NAME( --
                                   TABLE_NAME VARCHAR2 --
                                   ) RETURN VARCHAR2;
  FUNCTION MAKE( --
                TABLE_NAME        VARCHAR2
               ,CTRL_PACKAGE_NAME OUT VARCHAR2
               ,APP_PACKAGE_NAME  OUT VARCHAR2
                --
                ) RETURN VARCHAR2;

  FUNCTION MAKE_DBMS_OUTPUT( --
                            TABLE_NAME        VARCHAR2
                           ,CTRL_PACKAGE_NAME OUT VARCHAR2
                           ,APP_PACKAGE_NAME  OUT VARCHAR2
                            --
                            ) RETURN VARCHAR2;
END;
/
CREATE OR REPLACE PACKAGE BODY MAM_APP_MAKER_PKG IS
  C_IS_PK CONSTANT NUMBER := 1;
  GV_TABLENAME VARCHAR2(128);
  CURSOR TABLE_COLUMNS(P_IS_PK NUMBER) IS
    WITH CURSOR_TABLE AS
     ( --
      SELECT DISTINCT TC.COLUMN_ID
                      ,TC.TABLE_NAME
                      ,TC.COLUMN_NAME
                      ,CASE
                         WHEN TC.DATA_TYPE IN ('NUMBER', 'DATE')
                              AND CC.TABLE_NAME IS NULL THEN
                          1
                         ELSE
                          0
                       END AS SUBJECT_OF_FROM_TO
                      ,NVL(PK.IS_PK, 0) AS IS_PK
      /*
                            ,TC.DATA_TYPE
                            ,TC.DATA_LENGTH
                            ,CASE
                               WHEN CC.TABLE_NAME IS NULL THEN
                                0
                               ELSE
                                1
                             END AS IS_ON_FK
      */
        FROM ALL_TAB_COLUMNS TC
        LEFT OUTER JOIN ( --
                         SELECT TO_NUMBER(CASE
                                             WHEN C.CONSTRAINT_TYPE = UPPER('P') THEN
                                              1
                                             ELSE
                                              0
                                           END) AS IS_PK
                                ,C.TABLE_NAME
                                ,CC.COLUMN_NAME
                           FROM ALL_CONSTRAINTS C
                          INNER JOIN ALL_CONS_COLUMNS CC
                             ON C.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
                                AND C.TABLE_NAME = CC.TABLE_NAME
                          WHERE C.CONSTRAINT_TYPE = UPPER('P')
                         --
                         ) PK
          ON TC.TABLE_NAME = PK.TABLE_NAME
             AND TC.COLUMN_NAME = PK.COLUMN_NAME
        LEFT OUTER JOIN (SELECT DISTINCT ACC.TABLE_NAME
                                        ,ACC.COLUMN_NAME
                           FROM ALL_CONSTRAINTS AC
                          INNER JOIN ALL_CONS_COLUMNS ACC
                             ON AC.CONSTRAINT_NAME = ACC.CONSTRAINT_NAME
                                AND AC.TABLE_NAME = ACC.TABLE_NAME
                          WHERE AC.CONSTRAINT_TYPE = UPPER('R')) CC
          ON TC.TABLE_NAME = CC.TABLE_NAME
             AND TC.COLUMN_NAME = CC.COLUMN_NAME
       WHERE UPPER(TC.TABLE_NAME) = UPPER(GV_TABLENAME)
             AND TC.COLUMN_NAME NOT IN ( --
                                        'CREATE_DATE'
                                       ,'CREATE_BY_DB_USER'
                                       ,'CREATE_BY_APP_USER'
                                       ,'LAST_UPDATE_DATE'
                                       ,'LAST_UPDATE_BY_DB_USER'
                                       ,'LAST_UPDATE_BY_APP_USER'
                                       ,'ATTACH_ID'
                                       ,'LAST_CHANGE_TS'
                                       ,'MODULE_NAME'
                                       ,'OS_USERNAME'
                                        --
                                       ,'LKP_COD_TRANSACTION_ACTION_MTR'
                                       ,'MSTP_SOURCE_TYPE_ID'
                                       ,'AMN_ACTUAL_MTRAN'
                                       ,'COD_COSTED_MTRAN'
                                       ,'ORPYD_ORPYM_NUM_ORD_PYM_ORPYM'
                                       ,'ORPYD_NUM_SEQ_ORPYD'
                                       ,'SPINV_NUM_SRL_SPINV'
                                       ,'DAT_STL_INVOICE_MTRAN'
                                       ,'COD_REVISION_MTRAN'
                                       ,'FLG_WAC_OPN_MTRAN'
                                       ,'NUM_WAC_ACC_MAIN_MTRAN'
                                       ,'NUM_WAC_ACC_CONT_MTRAN'
                                       ,'DAT_WAC_MTRAN'
                                       ,'AMN_STIMATE_MTRAN'
                                       ,'LKP_COD_FCT_MTRAN'
                                       ,'MRES_RESERVATION_ID'
                                       ,'LKP_STA_PENDING_MTRAN'
                                       ,'FLG_HAVE_BEFOR_INP_COST_MTRAN'
                                       ,'FLG_SLC_MTRAN'
                                       ,'LKP_COD_SYSTEM_MTRAN'
                                       ,'CCNTR_COD_CC_CCNTR_FROM'
                                       ,'SPINV_NUM_SRL_INNER_WAY'
                                       ,'LKP_TYP_MTYPE_MTRAN'
                                       ,'CCNTR_COD_CC_CCNTR_FROM'
                                       ,'QTY_ONHAND_PREVIOUS_MTRAN'
                                       ,'COD_REVISION_FOR_MTRAN'
                                       ,'NAM_UNIT_OF_MEASURE_PRIMARY_MT'
                                       ,'ID_TRANSFER_LOCATOR_MTRAN'
                                        --,'MSINV_NAM_SUB_INVENTORY_MSINV'
                                        --,'MSLOC_SUB_INVENTORY_LOCATOR_ID'
                                       ,'P_LKP_TYP_MTYPE_MTRAN'
                                       ,'P_LKP_COD_SYSTEM_MTRAN'
                                       ,'P_COD_REVISION_FOR_MTRAN'
                                       ,'P_LKP_STA_PENDING_MTRAN'
                                       ,'P_NAM_TRANSFER_SUBINVNTRY_MTRA'
                                        --,''
                                        )
      --
      )
    SELECT *
      FROM CURSOR_TABLE T
     WHERE (P_IS_PK IS NULL OR T.IS_PK = NVL(P_IS_PK, 0))
     ORDER BY T.IS_PK DESC
             ,T.COLUMN_ID;
  FUNCTION MAM_REMOVE_LAST_VOWEL_FUN(P_INPUT VARCHAR2) RETURN VARCHAR2 IS
    LV_CNTINU BOOLEAN := TRUE;
    LV_RESULT VARCHAR2(200);
    LV_INDEX  INT;
  BEGIN
    LV_RESULT := P_INPUT;
    LV_INDEX  := LENGTH(LV_RESULT) - 1;
    IF (LENGTH(LV_RESULT) > 2)
    THEN
      LOOP
        IF (UPPER(SUBSTR(LV_RESULT, LV_INDEX, 1)) IN
           ('A', 'E', 'I', 'O', 'U'))
        THEN
          LV_RESULT := SUBSTR(LV_RESULT, 1, LV_INDEX - 1) ||
                       SUBSTR(LV_RESULT, LV_INDEX + 1, LENGTH(LV_RESULT));
          LV_CNTINU := FALSE;
        END IF;
        LV_INDEX := LV_INDEX - 1;
        IF (LV_INDEX < 2)
        THEN
          LV_CNTINU := FALSE;
        END IF;
        EXIT WHEN NOT LV_CNTINU;
      END LOOP;
    END IF;
    RETURN LV_RESULT;
  END;
  FUNCTION MAM_REMOVE_LAST_UNDERLINE_FUN(P_INPUT VARCHAR2) RETURN VARCHAR2 IS
    LV_CNTINU BOOLEAN := TRUE;
    LV_RESULT VARCHAR2(200);
    LV_INDEX  INT;
  BEGIN
    LV_RESULT := P_INPUT;
    LV_INDEX  := LENGTH(LV_RESULT) - 1;
    IF (LENGTH(LV_RESULT) > 2)
    THEN
      LOOP
        IF (UPPER(SUBSTR(LV_RESULT, LV_INDEX, 1)) IN ('_'))
        THEN
          LV_RESULT := SUBSTR(LV_RESULT, 1, LV_INDEX - 1) ||
                       SUBSTR(LV_RESULT, LV_INDEX + 1, LENGTH(LV_RESULT));
          LV_CNTINU := FALSE;
        END IF;
        LV_INDEX := LV_INDEX - 1;
        IF (LV_INDEX < 2)
        THEN
          LV_CNTINU := FALSE;
        END IF;
        EXIT WHEN NOT LV_CNTINU;
      END LOOP;
    END IF;
    RETURN LV_RESULT;
  END;
  FUNCTION MAM_REMOVE_LAST_VWL_UNDRLN_FUN(P_INPUT VARCHAR2) RETURN VARCHAR2 IS
    LV_CNTINU BOOLEAN := TRUE;
    LV_RESULT VARCHAR2(200);
    LV_INDEX  INT;
  BEGIN
    LV_RESULT := P_INPUT;
    LV_INDEX  := LENGTH(LV_RESULT) - 1;
    IF (LENGTH(LV_RESULT) > 2)
    THEN
      LOOP
        IF (UPPER(SUBSTR(LV_RESULT, LV_INDEX, 1)) IN
           ('A', 'E', 'I', 'O', 'U', '_'))
        THEN
          LV_RESULT := SUBSTR(LV_RESULT, 1, LV_INDEX - 1) ||
                       SUBSTR(LV_RESULT, LV_INDEX + 1, LENGTH(LV_RESULT));
          LV_CNTINU := FALSE;
        END IF;
        LV_INDEX := LV_INDEX - 1;
        IF (LV_INDEX < 2)
        THEN
          LV_CNTINU := FALSE;
        END IF;
        EXIT WHEN NOT LV_CNTINU;
      END LOOP;
    END IF;
    RETURN LV_RESULT;
  END;
  FUNCTION MAM_REMOVE_VOWELS_FUN(P_INPUT         VARCHAR2
                                ,P_RESULT_LENGTH INT) RETURN VARCHAR2 IS
    LV_CNTINU BOOLEAN;
    LV_RESULT VARCHAR2(200);
    LV_TMP    VARCHAR2(200);
  BEGIN
    LV_RESULT := P_INPUT;
    IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1)
    THEN
      LV_CNTINU := FALSE;
    ELSE
      LV_CNTINU := TRUE;
    END IF;
    WHILE LV_CNTINU
    LOOP
      LV_TMP := MAM_REMOVE_LAST_VOWEL_FUN(LV_RESULT);
      IF (LV_TMP = LV_RESULT)
      THEN
        LV_CNTINU := FALSE;
      ELSE
        LV_RESULT := LV_TMP;
      END IF;
      IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1)
      THEN
        LV_CNTINU := FALSE;
      END IF;
    END LOOP;
    RETURN LV_RESULT;
  END;
  FUNCTION MAM_REMOVE_UNDERLINES_FUN(P_INPUT         VARCHAR2
                                    ,P_RESULT_LENGTH INT) RETURN VARCHAR2 IS
    LV_CNTINU BOOLEAN;
    LV_RESULT VARCHAR2(200);
    LV_TMP    VARCHAR2(200);
  BEGIN
    LV_RESULT := P_INPUT;
    IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1)
    THEN
      LV_CNTINU := FALSE;
    ELSE
      LV_CNTINU := TRUE;
    END IF;
    WHILE LV_CNTINU
    LOOP
      LV_TMP := MAM_REMOVE_LAST_UNDERLINE_FUN(LV_RESULT);
      IF (LV_TMP = LV_RESULT)
      THEN
        LV_CNTINU := FALSE;
      ELSE
        LV_RESULT := LV_TMP;
      END IF;
      IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1)
      THEN
        LV_CNTINU := FALSE;
      END IF;
    END LOOP;
    RETURN LV_RESULT;
  END;
  FUNCTION MAM_PACK_INPUT_FUN(P_INPUT         VARCHAR2
                             ,P_RESULT_LENGTH INT) RETURN VARCHAR2 IS
    LV_CNTINU BOOLEAN;
    LV_RESULT VARCHAR2(200);
    LV_TMP    VARCHAR2(200);
  BEGIN
    LV_RESULT := P_INPUT;
    IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1)
    THEN
      LV_CNTINU := FALSE;
    ELSE
      LV_CNTINU := TRUE;
    END IF;
    WHILE LV_CNTINU
    LOOP
      LV_TMP := MAM_REMOVE_LAST_VWL_UNDRLN_FUN(LV_RESULT);
      IF (LV_TMP = LV_RESULT)
      THEN
        LV_CNTINU := FALSE;
      ELSE
        LV_RESULT := LV_TMP;
      END IF;
      IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1)
      THEN
        LV_CNTINU := FALSE;
      END IF;
    
    END LOOP;
    RETURN LV_RESULT;
  END;

  FUNCTION TABLE_COMMENT_FUN RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(1000);
  BEGIN
    BEGIN
      SELECT REPLACE(REPLACE(REPLACE(TRIM(REPLACE(TC.COMMENTS
                                                 ,'ÃœÊ·'
                                                 ,''))
                                    ,'  '
                                    ,' ')
                            ,'  '
                            ,' ')
                    ,'  '
                    ,' ')
        INTO LV_RESULT
        FROM ALL_TAB_COMMENTS TC
       WHERE TC.TABLE_NAME = UPPER(TRIM(GV_TABLENAME));
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    LV_RESULT := 'ÃœÊ· ' || NVL(LV_RESULT, GV_TABLENAME);
    RETURN LV_RESULT;
  END;

  FUNCTION CREATE_COLUMN_TYPE_STRING( --
                                     COLUMN_NAME VARCHAR2 --
                                     ) RETURN VARCHAR2 IS
  BEGIN
    RETURN UPPER(GV_TABLENAME || '.' || COLUMN_NAME || '%TYPE');
  END;
  FUNCTION CREATE_COLUMN_TYPE( --
                              COLUMN_NAME VARCHAR2 --
                              ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_COLUMN_TYPE_STRING( --
                                     COLUMN_NAME --
                                     );
  END;
  FUNCTION CREATE_PARAMETER_NAME( --
                                 COLUMN_NAME VARCHAR2 --
                                 ) RETURN VARCHAR2 IS
  BEGIN
    RETURN UPPER('P_' || MAM_REMOVE_VOWELS_FUN(COLUMN_NAME, 28));
  END;
  FUNCTION CREATE_PARAMETER_TYPE( --
                                 COLUMN_NAME VARCHAR2 --
                                 ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_COLUMN_TYPE_STRING( --
                                     COLUMN_NAME --
                                     );
  END;
  ---------------------------------------------------------
  FUNCTION CREATE_FPV_NAME( --
                           PREFIX  VARCHAR2
                          ,INFIX   VARCHAR2
                          ,POSTFIX VARCHAR2 --
                           ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(128);
  BEGIN
    /*
        LV_RESULT := UPPER(MAM_REMOVE_VOWELS_FUN(PREFIX || INFIX || POSTFIX
                                                ,30 - LENGTH(PREFIX || POSTFIX)));
    */
    LV_RESULT := UPPER(MAM_PACK_INPUT_FUN(PREFIX || INFIX || POSTFIX, 30));
    IF LENGTH(LV_RESULT) > 30
    THEN
      LV_RESULT := MAM_REMOVE_VOWELS_FUN(LV_RESULT, 30);
    END IF;
    IF LENGTH(LV_RESULT) > 30
    THEN
      LV_RESULT := MAM_REMOVE_UNDERLINES_FUN(LV_RESULT, 30);
    END IF;
    RETURN LV_RESULT;
  END;
  ---------------------------------------------------------
  FUNCTION CREATE_SETTER_NAME( --
                              COLUMN_NAME VARCHAR2 --
                              ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('SET_', COLUMN_NAME, NULL);
  END;
  FUNCTION CREATE_GETTER_NAME( --
                              COLUMN_NAME VARCHAR2 --
                              ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('GET_', COLUMN_NAME, NULL);
  END;

  FUNCTION CREATE_SETTER_FROM_NAME( --
                                   COLUMN_NAME VARCHAR2 --
                                   ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('SET_', COLUMN_NAME, '_FROM');
  END;
  FUNCTION CREATE_GETTER_FROM_NAME( --
                                   COLUMN_NAME VARCHAR2 --
                                   ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('GET_', COLUMN_NAME, '_FROM');
  END;
  FUNCTION CREATE_SETTER_TO_NAME( --
                                 COLUMN_NAME VARCHAR2 --
                                 ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('SET_', COLUMN_NAME, '_TO');
  END;
  FUNCTION CREATE_GETTER_TO_NAME( --
                                 COLUMN_NAME VARCHAR2 --
                                 ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('GET_', COLUMN_NAME, '_TO');
  END;
  FUNCTION CREATE_GLOBAL_VARIABLE_NAME( --
                                       COLUMN_NAME VARCHAR2 --
                                       ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('GV_', COLUMN_NAME, NULL);
  END;

  FUNCTION CREATE_GLOBAL_FROM_VARIBL_NAME( --
                                          COLUMN_NAME VARCHAR2 --
                                          ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('GV_', COLUMN_NAME, '_FROM');
  END;
  FUNCTION CREATE_GLOBAL_TO_VARIABLE_NAME( --
                                          COLUMN_NAME VARCHAR2 --
                                          ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('GV_', COLUMN_NAME, '_TO');
  END;

  FUNCTION CREATE_LOCAL_VARIABLE_NAME( --
                                      COLUMN_NAME VARCHAR2 --
                                      ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CREATE_FPV_NAME('LV_', COLUMN_NAME, NULL);
  END;

  FUNCTION CREATE_CTRL_PACKAGE_NAME( --
                                    TABLE_NAME VARCHAR2 --
                                    ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(128);
    C_PREFIX  CONSTANT VARCHAR2(10) := NULL;
    C_POSTFIX CONSTANT VARCHAR2(10) := '_CTRL_PKG';
  BEGIN
    LV_RESULT := UPPER(C_PREFIX ||
                       MAM_PACK_INPUT_FUN(TABLE_NAME
                                         ,30 -
                                          (LENGTH(C_PREFIX || C_POSTFIX))) ||
                       C_POSTFIX);
    IF LENGTH(LV_RESULT) > 30
    THEN
      LV_RESULT := MAM_REMOVE_VOWELS_FUN(LV_RESULT, 30);
    END IF;
    IF LENGTH(LV_RESULT) > 30
    THEN
      LV_RESULT := MAM_REMOVE_UNDERLINES_FUN(LV_RESULT, 30);
    END IF;
    RETURN LV_RESULT;
  
  END;
  FUNCTION CREATE_CTRL_PACKAGE_DECLARATION( --
                                           TABLE_NAME   VARCHAR2
                                          ,SPEC_OR_BODY VARCHAR2
                                           --
                                           ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(100);
  BEGIN
    IF UPPER(TRIM(NVL(SPEC_OR_BODY, 'spec'))) = UPPER(TRIM('spec'))
    THEN
      LV_RESULT := 'CREATE PACKAGE ' ||
                   CREATE_CTRL_PACKAGE_NAME(TABLE_NAME) || ' IS';
    ELSE
      LV_RESULT := 'CREATE PACKAGE body ' ||
                   CREATE_CTRL_PACKAGE_NAME(TABLE_NAME) || ' IS';
    END IF;
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_APP_PACKAGE_NAME( --
                                   TABLE_NAME VARCHAR2 --
                                   ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(128);
    C_PREFIX  CONSTANT VARCHAR2(10) := 'APP_';
    C_POSTFIX CONSTANT VARCHAR2(10) := '_PKG';
  BEGIN
    LV_RESULT := UPPER(C_PREFIX ||
                       MAM_PACK_INPUT_FUN(TABLE_NAME
                                         ,30 -
                                          (LENGTH(C_PREFIX || C_POSTFIX))) ||
                       C_POSTFIX);
    IF LENGTH(LV_RESULT) > 30
    THEN
      LV_RESULT := MAM_REMOVE_VOWELS_FUN(LV_RESULT, 30);
    END IF;
    IF LENGTH(LV_RESULT) > 30
    THEN
      LV_RESULT := MAM_REMOVE_UNDERLINES_FUN(LV_RESULT, 30);
    END IF;
    RETURN LV_RESULT;
  
  END;
  FUNCTION CREATE_APP_PACKAGE_DECLARATION( --
                                          TABLE_NAME   VARCHAR2
                                         ,SPEC_OR_BODY VARCHAR2
                                          --
                                          ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(100);
  BEGIN
    IF UPPER(TRIM(NVL(SPEC_OR_BODY, 'spec'))) = UPPER(TRIM('spec'))
    THEN
      LV_RESULT := 'CREATE PACKAGE ' || CREATE_APP_PACKAGE_NAME(TABLE_NAME) ||
                   ' IS';
    ELSE
      LV_RESULT := 'CREATE PACKAGE body ' ||
                   CREATE_APP_PACKAGE_NAME(TABLE_NAME) || ' IS';
    END IF;
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  ----------------------

  FUNCTION CREATE_SETTER_DECLARATION( --
                                     COLUMN_NAME VARCHAR2
                                    ,FROM_TO     VARCHAR2
                                     --
                                     ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(200);
  BEGIN
    IF TRIM(FROM_TO) IS NULL
    THEN
      LV_RESULT := CREATE_SETTER_NAME(COLUMN_NAME);
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('FROM'))
    THEN
      LV_RESULT := CREATE_SETTER_FROM_NAME(COLUMN_NAME);
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('to'))
    THEN
      LV_RESULT := CREATE_SETTER_TO_NAME(COLUMN_NAME);
    END IF;
    LV_RESULT := 'PROCEDURE ' || LV_RESULT || '(' ||
                 CREATE_PARAMETER_NAME(COLUMN_NAME) || ' ' ||
                 CREATE_COLUMN_TYPE(COLUMN_NAME) || ')';
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_SETTER_PRC_BODY( --
                                  COLUMN_NAME VARCHAR2
                                 ,FROM_TO     VARCHAR2
                                  --
                                  ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(200);
  BEGIN
    LV_RESULT := LV_RESULT || 'begin' || CHR(10);
    IF TRIM(FROM_TO) IS NULL
    THEN
      LV_RESULT := LV_RESULT || CREATE_GLOBAL_VARIABLE_NAME(COLUMN_NAME) || ':=' ||
                   CREATE_PARAMETER_NAME(COLUMN_NAME) || ';';
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('FROM'))
    THEN
      LV_RESULT := LV_RESULT ||
                   CREATE_GLOBAL_VARIABLE_NAME(COLUMN_NAME || '_from') ||
                   ' :=' || CREATE_PARAMETER_NAME(COLUMN_NAME) || ';';
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('to'))
    THEN
      LV_RESULT := LV_RESULT ||
                   CREATE_GLOBAL_VARIABLE_NAME(COLUMN_NAME || '_to') ||
                   ' :=' || CREATE_PARAMETER_NAME(COLUMN_NAME) || ';';
    END IF;
    LV_RESULT := UPPER(LV_RESULT || CHR(10) || 'END;' || CHR(10));
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_GETTER_DECLARATION( --
                                     COLUMN_NAME VARCHAR2
                                    ,FROM_TO     VARCHAR2
                                     --
                                     ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(200);
  BEGIN
    IF TRIM(FROM_TO) IS NULL
    THEN
      LV_RESULT := CREATE_GETTER_NAME(COLUMN_NAME);
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('FROM'))
    THEN
      LV_RESULT := CREATE_GETTER_FROM_NAME(COLUMN_NAME);
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('to'))
    THEN
      LV_RESULT := CREATE_GETTER_TO_NAME(COLUMN_NAME);
    END IF;
    LV_RESULT := 'FUNCTION ' || LV_RESULT || ' RETURN ' ||
                 CREATE_COLUMN_TYPE(COLUMN_NAME);
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_GETTER_FUN_BODY( --
                                  COLUMN_NAME VARCHAR2
                                 ,FROM_TO     VARCHAR2
                                  --
                                  ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(200);
  BEGIN
    LV_RESULT := LV_RESULT || 'begin' || CHR(10) || 'RETURN ';
    IF TRIM(FROM_TO) IS NULL
    THEN
      LV_RESULT := LV_RESULT || CREATE_GLOBAL_VARIABLE_NAME(COLUMN_NAME) || ';';
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('FROM'))
    THEN
      LV_RESULT := LV_RESULT ||
                   CREATE_GLOBAL_VARIABLE_NAME(COLUMN_NAME || '_from') || ';';
    ELSIF UPPER(TRIM(FROM_TO)) = UPPER(TRIM('to'))
    THEN
      LV_RESULT := LV_RESULT ||
                   CREATE_GLOBAL_VARIABLE_NAME(COLUMN_NAME || '_to') || ';';
    END IF;
    LV_RESULT := LV_RESULT || CHR(10) || 'end;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_GETTER_SETTER_SPEC RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(32767);
    I         NUMBER;
  BEGIN
    --GETTER_AND_SETTER
    I := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT := LV_RESULT || '-- GETTER AND SETTER FOR ' ||
                   C.COLUMN_NAME ||
                   ' --------------------------------------' || CHR(10);
      LV_RESULT := LV_RESULT || CREATE_SETTER_DECLARATION( --
                                                          C.COLUMN_NAME
                                                         ,NULL --FROM_TO     
                                                          --
                                                          ) || ';--' ||
                   TO_CHAR(I) || '--' || CHR(10);
      IF (C.SUBJECT_OF_FROM_TO = 1)
      THEN
        LV_RESULT := LV_RESULT || CREATE_SETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'FROM'
                                                            --
                                                            ) || ';--' ||
                     TO_CHAR(I) || '--' || CHR(10);
        LV_RESULT := LV_RESULT || CREATE_SETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'TO'
                                                            --
                                                            ) || ';--' ||
                     TO_CHAR(I) || '--' || CHR(10);
      END IF;
      LV_RESULT := LV_RESULT || CREATE_GETTER_DECLARATION( --
                                                          C.COLUMN_NAME
                                                         ,NULL --FROM_TO     
                                                          --
                                                          ) || ';--' ||
                   TO_CHAR(I) || '--' || CHR(10);
      IF (C.SUBJECT_OF_FROM_TO = 1)
      THEN
        LV_RESULT := LV_RESULT || CREATE_GETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'FROM'
                                                            --
                                                            ) || ';--' ||
                     TO_CHAR(I) || '--' || CHR(10);
        LV_RESULT := LV_RESULT || CREATE_GETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'TO'
                                                            --
                                                            ) || ';--' ||
                     TO_CHAR(I) || '--' || CHR(10);
      END IF;
      I := I + 1;
    END LOOP;
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_GETTER_SETTER_BODY RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(32767);
    I         NUMBER;
  BEGIN
    --GETTER_AND_SETTER
    I := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT := LV_RESULT || '-- GETTER AND SETTER FOR ' ||
                   C.COLUMN_NAME ||
                   ' --------------------------------------' || CHR(10);
      LV_RESULT := LV_RESULT || CREATE_SETTER_DECLARATION( --
                                                          C.COLUMN_NAME
                                                         ,NULL --FROM_TO     
                                                          --
                                                          ) ||
                   UPPER(' is --') || TO_CHAR(I) || '--' || CHR(10);
      LV_RESULT := LV_RESULT || CREATE_SETTER_PRC_BODY( --
                                                       C.COLUMN_NAME
                                                      ,NULL --FROM_TO     
                                                       --
                                                       );
      IF (C.SUBJECT_OF_FROM_TO = 1)
      THEN
        LV_RESULT := LV_RESULT || CREATE_SETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'FROM'
                                                            --
                                                            ) ||
                     UPPER(' is --') || TO_CHAR(I) || '--' || CHR(10);
        LV_RESULT := LV_RESULT || CREATE_SETTER_PRC_BODY( --
                                                         C.COLUMN_NAME
                                                        ,'FROM' --FROM_TO     
                                                         --
                                                         );
        LV_RESULT := LV_RESULT || CREATE_SETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'TO'
                                                            --
                                                            ) ||
                     UPPER(' is --') || TO_CHAR(I) || '--' || CHR(10);
        LV_RESULT := LV_RESULT || CREATE_SETTER_PRC_BODY( --
                                                         C.COLUMN_NAME
                                                        ,'to' --FROM_TO     
                                                         --
                                                         );
      END IF;
    
      LV_RESULT := LV_RESULT || CREATE_GETTER_DECLARATION( --
                                                          C.COLUMN_NAME
                                                         ,NULL --FROM_TO     
                                                          --
                                                          ) ||
                   UPPER(' is --') || TO_CHAR(I) || '--' || CHR(10);
      LV_RESULT := LV_RESULT || CREATE_GETTER_FUN_BODY( --
                                                       C.COLUMN_NAME
                                                      ,NULL --FROM_TO     
                                                       --
                                                       );
      IF (C.SUBJECT_OF_FROM_TO = 1)
      THEN
        LV_RESULT := LV_RESULT || CREATE_GETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'FROM'
                                                            --
                                                            ) ||
                     UPPER(' is --') || TO_CHAR(I) || '--' || CHR(10);
        LV_RESULT := LV_RESULT || CREATE_GETTER_FUN_BODY( --
                                                         C.COLUMN_NAME
                                                        ,'FROM' --FROM_TO     
                                                         --
                                                         );
        LV_RESULT := LV_RESULT || CREATE_GETTER_DECLARATION( --
                                                            C.COLUMN_NAME
                                                           ,'TO'
                                                            --
                                                            ) ||
                     UPPER(' is --') || TO_CHAR(I) || '--' || CHR(10);
        LV_RESULT := LV_RESULT || CREATE_GETTER_FUN_BODY( --
                                                         C.COLUMN_NAME
                                                        ,'TO' --FROM_TO     
                                                         --
                                                         );
      END IF;
      I := I + 1;
    END LOOP;
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_GLOBAL_VARIABLES_BODY RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(32767);
    I         NUMBER;
  BEGIN
    --GETTER_AND_SETTER
    LV_RESULT := LV_RESULT ||
                 '-- GLOBAL VARIABLES --------------------------------------' ||
                 CHR(10);
    I         := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT := LV_RESULT || CREATE_GLOBAL_VARIABLE_NAME( --
                                                            C.COLUMN_NAME
                                                            --
                                                            ) || ' ' ||
                   CREATE_COLUMN_TYPE( --
                                      C.COLUMN_NAME
                                      --
                                      ) || ';--' || TO_CHAR(I) || '--' ||
                   CHR(10);
      IF (C.SUBJECT_OF_FROM_TO = 1)
      THEN
        LV_RESULT := LV_RESULT ||
                     CREATE_GLOBAL_FROM_VARIBL_NAME( --
                                                    C.COLUMN_NAME
                                                    --
                                                    ) || ' ' ||
                     CREATE_COLUMN_TYPE( --
                                        C.COLUMN_NAME
                                        --
                                        ) || ';--' || TO_CHAR(I) || '--' ||
                     CHR(10);
        LV_RESULT := LV_RESULT ||
                     CREATE_GLOBAL_TO_VARIABLE_NAME( --
                                                    C.COLUMN_NAME
                                                    --
                                                    ) || ' ' ||
                     CREATE_COLUMN_TYPE( --
                                        C.COLUMN_NAME
                                        --
                                        ) || ';--' || TO_CHAR(I) || '--' ||
                     CHR(10);
      END IF;
      I := I + 1;
    END LOOP;
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_CHECK_LOCK_DECLARATION RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT ||
                  '-- check_lock --------------------------------------' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'FUNCTION check_lock(--' || CHR(10);
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ' ' ||
                      CREATE_PARAMETER_TYPE(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--' || CHR(10);
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || ') RETURN VARCHAR2';
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_CHECK_LOCK_BODY RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT || CREATE_CHECK_LOCK_DECLARATION || ' is ' ||
                  CHR(10) || 'LV_RESULT VARCHAR2(1000):='''';' || CHR(10);
    DELIMITTER := NULL;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER ||
                      CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME) || ' ' ||
                      CREATE_COLUMN_TYPE(C.COLUMN_NAME) || ';' || CHR(10);
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    LV_RESULT  := LV_RESULT || 'begin';
    LV_RESULT  := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT  := LV_RESULT || CHR(10) || 'select ';
    DELIMITTER := NULL;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER || C.COLUMN_NAME;
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    LV_RESULT  := LV_RESULT || ' into ';
    DELIMITTER := NULL;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER ||
                      CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME);
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || ' from ' || GV_TABLENAME ||
                 ' WHERE ';
    -- <WHERE parameters
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || C.COLUMN_NAME || '=' ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--';
        DELIMITTER := ' AND ';
      END IF;
      I := I + 1;
    END LOOP;
    --WHERE parameters>
    LV_RESULT := LV_RESULT || CHR(10) || 'for update nowait;' || CHR(10) ||
                 'EXCEPTION' || CHR(10) || ' WHEN NO_DATA_FOUND THEN
        NULL; WHEN OTHERS THEN ' || CHR(10) ||
                 'LV_RESULT := ''{—òÊ—œ ‘‰«”Â ';
    -- <WHERE parameters
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER || ''' ||to_char(' ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ')||''';
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    --WHERE parameters>
  
    LV_RESULT := LV_RESULT || ' «“ ' || TABLE_COMMENT_FUN ||
                 '  ﬁ›· ‘œÂ «” }'';';
    LV_RESULT := LV_RESULT || CHR(10) || 'END;';
    LV_RESULT := LV_RESULT || CHR(10) || 'RETURN LV_RESULT;' || CHR(10) ||
                 'end;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_CHECK_DATA_DECLARATION RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT ||
                  '-- CHECK_DATA --------------------------------------' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'FUNCTION CHECK_DATA(--' || CHR(10);
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || DELIMITTER ||
                    CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ' ' ||
                    CREATE_PARAMETER_TYPE(C.COLUMN_NAME) || '--' ||
                    TO_CHAR(I) || '--' || CHR(10);
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || ') RETURN VARCHAR2';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_CHECK_DATA_BODY RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
  BEGIN
    LV_RESULT  := LV_RESULT || CREATE_CHECK_DATA_DECLARATION || ' is ' ||
                  CHR(10) || 'LV_RESULT VARCHAR2(1000):='''';' || CHR(10) ||
                  'begin';
    LV_RESULT  := LV_RESULT || CHR(10) ||
                  'if LV_RESULT is null then LV_RESULT:=CHECK_LOCK(--' ||
                  CHR(10);
    DELIMITTER := NULL;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME);
        DELIMITTER := ', ';
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || '--' || CHR(10) || '); end if;';
    LV_RESULT := LV_RESULT || CHR(10) || 'RETURN LV_RESULT;' || CHR(10) ||
                 'end;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_ADD_DECLARATION RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT ||
                  '-- add --------------------------------------' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'FUNCTION add(--' || CHR(10);
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || DELIMITTER ||
                    CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ' ' ||
                   --
                    CASE
                      WHEN C.IS_PK = 1 THEN
                       'OUT '
                    END ||
                   --
                    CREATE_PARAMETER_TYPE(C.COLUMN_NAME) || '--' ||
                    TO_CHAR(I) || '--' || CHR(10);
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || ') RETURN VARCHAR2';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_ADD_BODY RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT := LV_RESULT || CREATE_ADD_DECLARATION || ' is ' || CHR(10) ||
                 'LV_RESULT VARCHAR2(1000):='''';' || CHR(10) || 'begin';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_RESULT:=' ||
                 CREATE_CTRL_PACKAGE_NAME(GV_TABLENAME) || '.CHECK_DATA(--';
    -- <parameters to check
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER ||
                    CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                    TO_CHAR(I) || '--';
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    --parameters to check>
    LV_RESULT := LV_RESULT || CHR(10) || ');';
    LV_RESULT := LV_RESULT || CHR(10) || 'IF (LV_RESULT IS NULL) THEN';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) || 'INSERT INTO ' || GV_TABLENAME ||
                 CHR(10) || '(';
    -- <insert fields
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || C.COLUMN_NAME || '--' ||
                    TO_CHAR(I) || '--';
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    --insert fields>
    LV_RESULT := LV_RESULT || CHR(10) || ')' || CHR(10) || 'VALUES' ||
                 CHR(10) || '(';
    -- <insert parameters
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER ||
                    CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                    TO_CHAR(I) || '--';
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    --insert parameters>
    LV_RESULT := LV_RESULT || CHR(10) || ');' || CHR(10) || 'EXCEPTION' ||
                 CHR(10) || ' WHEN OTHERS THEN ' || CHR(10) ||
                 'LV_RESULT := ''{—òÊ—œÌ œ— ' || TABLE_COMMENT_FUN ||
                 ' œ—Ã ‰‘œ}'';' || CHR(10) || 'END;' || CHR(10) ||
                 'END IF;';
    LV_RESULT := LV_RESULT || CHR(10) || 'RETURN LV_RESULT;' || CHR(10) ||
                 'end;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_REMOVE_DECLARATION RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT ||
                  '-- remove --------------------------------------' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'FUNCTION remove(--' || CHR(10);
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ' ' ||
                      CREATE_PARAMETER_TYPE(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--' || CHR(10);
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || ') RETURN VARCHAR2';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_REMOVE_BODY RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT := LV_RESULT || CREATE_REMOVE_DECLARATION || ' is ' ||
                 CHR(10) || 'LV_RESULT VARCHAR2(1000):='''';' || CHR(10) ||
                 'begin';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) || 'DELETE ' || GV_TABLENAME ||
                 ' WHERE ';
    -- <REMOVE parameters
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || C.COLUMN_NAME || '=' ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--';
        DELIMITTER := ' AND ';
      END IF;
      I := I + 1;
    END LOOP;
    --REMOVE parameters>
    LV_RESULT := LV_RESULT || CHR(10) || ';' || CHR(10) || 'EXCEPTION' ||
                 CHR(10) || ' WHEN OTHERS THEN ' || CHR(10) ||
                 'LV_RESULT := ''{»Â œ·Ì· «” ›«œÂ «“ —òÊ—œ œ— œÌê— Ãœ«Ê·° Õ–› ¬‰ «“ ' ||
                 TABLE_COMMENT_FUN || ' «„ò«‰Å–Ì— ‰Ì” }'';' || CHR(10) ||
                 'END;';
    LV_RESULT := LV_RESULT || CHR(10) || 'RETURN LV_RESULT;' || CHR(10) ||
                 'end;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_EDIT_DECLARATION RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT ||
                  '-- edit --------------------------------------' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'FUNCTION edit(--' || CHR(10);
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || DELIMITTER ||
                    CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ' ' ||
                   /*
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                --
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 CASE
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   WHEN C.IS_PK = 1 THEN
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    'IN OUT '
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 END ||
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                --
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                */
                    CREATE_PARAMETER_TYPE(C.COLUMN_NAME) || '--' ||
                    TO_CHAR(I) || '--' || CHR(10);
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || ') RETURN VARCHAR2';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_EDIT_BODY RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT := LV_RESULT || CREATE_EDIT_DECLARATION || ' is ' || CHR(10) ||
                 'LV_RESULT VARCHAR2(1000):='''';' || CHR(10) || 'begin';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_RESULT:=' ||
                 CREATE_CTRL_PACKAGE_NAME(GV_TABLENAME) || '.CHECK_DATA(';
    -- <parameters to check
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER ||
                    CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                    TO_CHAR(I) || '--';
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    --parameters to check>
    LV_RESULT := LV_RESULT || CHR(10) || ');';
    LV_RESULT := LV_RESULT || CHR(10) || 'IF (LV_RESULT IS NULL) THEN' ||
                 CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) || 'UPDATE ' || GV_TABLENAME ||
                 ' SET ';
    -- <edit fields
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || C.COLUMN_NAME || '=' ||
                    CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                    TO_CHAR(I) || '--';
      DELIMITTER := ', ';
      I          := I + 1;
    END LOOP;
    --edit fields>
    LV_RESULT := LV_RESULT || CHR(10) || ' WHERE ';
    -- <edit parameters
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || C.COLUMN_NAME || '=';
        LV_RESULT  := LV_RESULT || CHR(10) ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--';
        DELIMITTER := ' AND ';
      END IF;
      I := I + 1;
    END LOOP;
    --edit parameters>
    LV_RESULT := LV_RESULT || CHR(10) || ';' || CHR(10) || 'EXCEPTION' ||
                 CHR(10) || ' WHEN OTHERS THEN ' || CHR(10) ||
                 'LV_RESULT := ''{ €ÌÌ—Ì œ— —òÊ—œ ’Ê—  ‰ê—› }'';' ||
                 CHR(10) || 'END;' || CHR(10) || 'END IF;';
    LV_RESULT := LV_RESULT || CHR(10) || 'RETURN LV_RESULT;' || CHR(10) ||
                 'end;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_CREATE_FILTER_VIEW_BODY RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
  BEGIN
    LV_RESULT := LV_RESULT ||
                 '-- CREATE_FILTER_VIEW --------------------------------------' ||
                 CHR(10);
    LV_RESULT := LV_RESULT || 'PROCEDURE CREATE_FILTER_VIEW(--' || CHR(10);
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'P_FILTER_VIEW_NAME VARCHAR2, COMMA_SEPARATED_IDS VARCHAR2) is';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL VARCHAR2(4000);';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'C_DATE CONSTANT VARCHAR2(100) := TO_CHAR(SYSDATE,''RRRR/MM/DD HH24:MI:SS'',''NLS_CALENDAR=PERSIAN'');';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'LV_SQL := ''CREATE OR REPLACE VIEW '' || P_FILTER_VIEW_NAME ||'' AS ''';
    LV_RESULT := LV_RESULT || CHR(10) || '|| CHR(10)||''SELECT ''';
    -- <edit fields
    DELIMITTER := '||''';
    FOR C IN TABLE_COLUMNS(NULL)
    LOOP
      LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || C.COLUMN_NAME || '''';
      DELIMITTER := ' || '',';
    END LOOP;
    --edit fields>
    LV_RESULT := LV_RESULT || CHR(10) || '|| '' FROM ' || GV_TABLENAME ||
                 ' WHERE ''';
    -- <where clause
    DELIMITTER := '||';
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || '''' ||
                      C.COLUMN_NAME ||
                      ' IN(-1''|| COMMA_SEPARATED_IDS ||'')''';
        DELIMITTER := '||'' AND ''';
      END IF;
    END LOOP;
    --where clause>
    LV_RESULT := LV_RESULT || CHR(10) || '--' || CHR(10) ||
                 '||CHR(10)||''/*''||C_DATE||''*/'';' || CHR(10) ||
                 'APP_MAM_GLOBAL_TEMPS_PKG.EXEC_IMDT(LV_SQL);' || CHR(10) ||
                 'END;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_ADD_TO_FILTER_VIEW_DCLR RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT ||
                  '-- ADD_TO_FILTER_VIEW --------------------------------------' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'PROCEDURE ADD_TO_FILTER_VIEW(--' || CHR(10);
    LV_RESULT  := LV_RESULT || 'P_FILTER_VIEW_NAME IN OUT VARCHAR2';
    DELIMITTER := ',';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ' ' ||
                      CREATE_PARAMETER_TYPE(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--' || CHR(10);
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || ') ';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_ADD_TO_FILTER_VIEW_BODY RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT := LV_RESULT || CREATE_ADD_TO_FILTER_VIEW_DCLR || ' is';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'TYPE ITEM_FILTER_CURSOR_TYPE IS REF CURSOR;';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'LV_FILTER  ITEM_FILTER_CURSOR_TYPE;' || CHR(10) ||
                 'LV_SQL     VARCHAR2(4000);' || CHR(10) ||
                 'LV_EXISTS  NUMBER;';
    -- <local variables
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT := LV_RESULT || CHR(10) ||
                     CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME) || ' ' ||
                     CREATE_COLUMN_TYPE(C.COLUMN_NAME) || ';';
      END IF;
    END LOOP;
    --local variables>
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN' || CHR(10) ||
                 'IF P_FILTER_VIEW_NAME IS NULL THEN' || CHR(10) ||
                 'P_FILTER_VIEW_NAME := APP_MAM_UTILITY_PKG.GENERATE_VIEW_NAME;';
    -- <parameters
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL:=LV_SQL' ||
                     '||'',''||' || CREATE_PARAMETER_NAME(C.COLUMN_NAME);
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || ';';
    --parameters>
    LV_RESULT := LV_RESULT || CHR(10) || 'ELSE';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'OPEN LV_FILTER FOR ''SELECT DISTINCT ''';
    -- <select clause
    DELIMITTER := '||';
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || '''' ||
                      C.COLUMN_NAME || '''';
        DELIMITTER := '||'' ,''';
      END IF;
    END LOOP;
    --select clause>
    LV_RESULT := LV_RESULT || CHR(10) ||
                 '||'' FROM '' || P_FILTER_VIEW_NAME;';
    LV_RESULT := LV_RESULT || CHR(10) || 'LOOP';
    LV_RESULT := LV_RESULT || CHR(10) || 'FETCH LV_FILTER';
    LV_RESULT := LV_RESULT || CHR(10) || 'INTO ';
    -- <local variables
    DELIMITTER := '';
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER ||
                      CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME);
        DELIMITTER := ',';
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || ';';
    --local variables>
    LV_RESULT := LV_RESULT || CHR(10) || 'EXIT WHEN LV_FILTER%NOTFOUND;';
    -- <parameters
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL:=LV_SQL' ||
                     '||'',''||' ||
                     CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME);
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || ';';
    --parameters>
  
    LV_RESULT := LV_RESULT || CHR(10) || 'END LOOP;';
    LV_RESULT := LV_RESULT || CHR(10) || 'CLOSE LV_FILTER;';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) || 'SELECT 1';
    LV_RESULT := LV_RESULT || CHR(10) || 'INTO LV_EXISTS';
    LV_RESULT := LV_RESULT || CHR(10) || 'FROM DUAL';
    LV_RESULT := LV_RESULT || CHR(10) || 'WHERE EXISTS (SELECT NULL FROM ';
    LV_RESULT := LV_RESULT || CHR(10) || GV_TABLENAME || ' T ';
    LV_RESULT := LV_RESULT || CHR(10) || 'WHERE';
    -- <parameters
    DELIMITTER := '';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || C.COLUMN_NAME || '=';
        LV_RESULT  := LV_RESULT || CHR(10) ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--';
        DELIMITTER := ' AND ';
      END IF;
      I := I + 1;
    END LOOP;
    --parameters>
    LV_RESULT := LV_RESULT || CHR(10) || ');';
    LV_RESULT := LV_RESULT || CHR(10) || 'EXCEPTION';
    LV_RESULT := LV_RESULT || CHR(10) || 'WHEN NO_DATA_FOUND THEN';
    LV_RESULT := LV_RESULT || CHR(10) || 'NULL;';
    LV_RESULT := LV_RESULT || CHR(10) || 'END;';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_EXISTS := NVL(LV_EXISTS, 0);';
    LV_RESULT := LV_RESULT || CHR(10) || 'IF LV_EXISTS = 1';
    LV_RESULT := LV_RESULT || CHR(10) || 'THEN';
    -- <parameters
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL:=LV_SQL' ||
                     '||'',''||' || CREATE_PARAMETER_NAME(C.COLUMN_NAME);
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || ';';
    --parameters>
    LV_RESULT := LV_RESULT || CHR(10) || 'END IF;';
    LV_RESULT := LV_RESULT || CHR(10) || 'END IF;';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'CREATE_FILTER_VIEW(P_FILTER_VIEW_NAME, LV_SQL);';
    LV_RESULT := LV_RESULT || CHR(10) || 'END;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_REMOVEFROMFILTERVIW_DC RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
    I          NUMBER;
  BEGIN
    LV_RESULT  := LV_RESULT ||
                  '-- REMOVE_FROM_FILTER_VIEW --------------------------------------' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'PROCEDURE REMOVE_FROM_FILTER_VIEW(--' ||
                  CHR(10);
    LV_RESULT  := LV_RESULT || 'P_FILTER_VIEW_NAME VARCHAR2';
    DELIMITTER := ',';
    I          := 1;
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || DELIMITTER ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME) || ' ' ||
                      CREATE_PARAMETER_TYPE(C.COLUMN_NAME) || '--' ||
                      TO_CHAR(I) || '--' || CHR(10);
        DELIMITTER := ', ';
      END IF;
      I := I + 1;
    END LOOP;
    LV_RESULT := LV_RESULT || ') ';
    RETURN UPPER(TRIM(LV_RESULT));
  END;

  FUNCTION CREATE_REMOVEFROMFILTERVIW_BD RETURN VARCHAR2 IS
    LV_RESULT  VARCHAR2(32767);
    DELIMITTER VARCHAR2(10);
  BEGIN
    LV_RESULT := LV_RESULT || CREATE_REMOVEFROMFILTERVIW_DC || ' is';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'TYPE ITEM_FILTER_CURSOR_TYPE IS REF CURSOR;';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'LV_FILTER  ITEM_FILTER_CURSOR_TYPE;';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL     VARCHAR2(4000);';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_EXISTS  NUMBER;';
    -- <local variables
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT := LV_RESULT || CHR(10) ||
                     CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME) || ' ' ||
                     CREATE_COLUMN_TYPE(C.COLUMN_NAME) || ';';
      END IF;
    END LOOP;
    --local variables>
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'OPEN LV_FILTER FOR ''SELECT DISTINCT ''';
    -- <select clause
    DELIMITTER := '||';
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER || '''' ||
                      C.COLUMN_NAME || '''';
        DELIMITTER := '||'' ,''';
      END IF;
    END LOOP;
    --select clause>
    LV_RESULT := LV_RESULT || CHR(10) ||
                 '||'' FROM '' || P_FILTER_VIEW_NAME;';
    LV_RESULT := LV_RESULT || CHR(10) || 'LOOP';
    LV_RESULT := LV_RESULT || CHR(10) || 'FETCH LV_FILTER';
    LV_RESULT := LV_RESULT || CHR(10) || 'INTO ';
    -- <local variables
    DELIMITTER := '';
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER ||
                      CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME);
        DELIMITTER := ',';
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || ';';
    --local variables>
    LV_RESULT := LV_RESULT || CHR(10) || 'EXIT WHEN LV_FILTER%NOTFOUND;';
    LV_RESULT := LV_RESULT || CHR(10) || 'IF ';
    -- <parameters
    DELIMITTER := '';
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT  := LV_RESULT || CHR(10) || DELIMITTER ||
                      CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME) || '!=' ||
                      CREATE_PARAMETER_NAME(C.COLUMN_NAME);
        DELIMITTER := ' AND ';
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || 'THEN';
    -- <parameters
    FOR C IN TABLE_COLUMNS(C_IS_PK)
    LOOP
      IF (C.IS_PK = 1)
      THEN
        LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL:=LV_SQL' ||
                     '||'',''||' ||
                     CREATE_LOCAL_VARIABLE_NAME(C.COLUMN_NAME);
      END IF;
    END LOOP;
    LV_RESULT := LV_RESULT || CHR(10) || ';';
    --parameters>
    LV_RESULT := LV_RESULT || CHR(10) || 'END IF;';
  
    LV_RESULT := LV_RESULT || CHR(10) || 'END LOOP;';
    LV_RESULT := LV_RESULT || CHR(10) || 'CLOSE LV_FILTER;';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'CREATE_FILTER_VIEW(P_FILTER_VIEW_NAME, LV_SQL);';
    LV_RESULT := LV_RESULT || CHR(10) || 'END;';
  
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_DROP_FILTER_VIEW_DECLAR RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(32767);
  BEGIN
    LV_RESULT := LV_RESULT ||
                 '-- DROP_FILTER_VIEW --------------------------------------' ||
                 CHR(10);
    LV_RESULT := LV_RESULT || 'PROCEDURE DROP_FILTER_VIEW(--' || CHR(10);
    LV_RESULT := LV_RESULT || 'P_FILTER_VIEW_NAME IN OUT VARCHAR2' ||
                 CHR(10);
    LV_RESULT := LV_RESULT || '--' || CHR(10);
    LV_RESULT := LV_RESULT || ') ';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_DROP_FILTER_VIEW_BODY RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(32767);
  BEGIN
    LV_RESULT := LV_RESULT || CREATE_DROP_FILTER_VIEW_DECLAR || ' is';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL    VARCHAR2(4000);';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_EXISTS NUMBER;';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) || 'SELECT 1';
    LV_RESULT := LV_RESULT || CHR(10) || 'INTO LV_EXISTS';
    LV_RESULT := LV_RESULT || CHR(10) || 'FROM DUAL';
    LV_RESULT := LV_RESULT || CHR(10) || 'WHERE EXISTS (SELECT NULL';
    LV_RESULT := LV_RESULT || CHR(10) || 'FROM ALL_VIEWS V';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'WHERE V.VIEW_NAME = UPPER(P_FILTER_VIEW_NAME));';
    LV_RESULT := LV_RESULT || CHR(10) || 'EXCEPTION';
    LV_RESULT := LV_RESULT || CHR(10) || 'WHEN NO_DATA_FOUND THEN';
    LV_RESULT := LV_RESULT || CHR(10) || 'NULL;';
    LV_RESULT := LV_RESULT || CHR(10) || 'END;';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_EXISTS := NVL(LV_EXISTS, 0);';
    LV_RESULT := LV_RESULT || CHR(10) || 'IF LV_EXISTS = 1';
    LV_RESULT := LV_RESULT || CHR(10) || 'THEN';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'LV_SQL := ''DROP VIEW '' || P_FILTER_VIEW_NAME;';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'APP_MAM_GLOBAL_TEMPS_PKG.EXEC_IMDT(LV_SQL);';
    LV_RESULT := LV_RESULT || CHR(10) || 'END IF;' || CHR(10) || 'END;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_COUNT_FILTER_RECORDS_DC RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(32767);
  BEGIN
    LV_RESULT := LV_RESULT ||
                 '-- COUNT_FILTER_RECORDS --------------------------------------' ||
                 CHR(10);
    LV_RESULT := LV_RESULT || 'FUNCTION COUNT_FILTER_RECORDS(--' || CHR(10);
    LV_RESULT := LV_RESULT || 'P_FILTER_VIEW_NAME IN OUT VARCHAR2' ||
                 CHR(10);
    LV_RESULT := LV_RESULT || '--' || CHR(10);
    LV_RESULT := LV_RESULT || ')  RETURN NUMBER ';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  FUNCTION CREATE_COUNT_FILTER_RECORDS_BD RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(32767);
  BEGIN
    LV_RESULT := LV_RESULT || CREATE_COUNT_FILTER_RECORDS_DC || ' is ';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_SQL VARCHAR2(200);';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_CNT NUMBER;';
    LV_RESULT := LV_RESULT || CHR(10) || 'PRAGMA AUTONOMOUS_TRANSACTION;';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) ||
                 'LV_SQL := '' SELECT COUNT(1) FROM '' || P_FILTER_VIEW_NAME;';
    LV_RESULT := LV_RESULT || CHR(10) || 'BEGIN';
    LV_RESULT := LV_RESULT || CHR(10) || 'EXECUTE IMMEDIATE LV_SQL';
    LV_RESULT := LV_RESULT || CHR(10) || 'INTO LV_CNT;';
    LV_RESULT := LV_RESULT || CHR(10) || 'EXCEPTION';
    LV_RESULT := LV_RESULT || CHR(10) || 'WHEN OTHERS THEN';
    LV_RESULT := LV_RESULT || CHR(10) || 'NULL;';
    LV_RESULT := LV_RESULT || CHR(10) || 'END;';
    LV_RESULT := LV_RESULT || CHR(10) || 'LV_CNT := NVL(LV_CNT, 0);';
    LV_RESULT := LV_RESULT || CHR(10) || 'RETURN LV_CNT;';
    LV_RESULT := LV_RESULT || CHR(10) || 'END;';
    RETURN UPPER(TRIM(LV_RESULT));
  END;
  /**********************************************************************************/
  /**********************************************************************************/
  /**********************************************************************************/
  /**********************************************************************************/
  /**********************************************************************************/
  FUNCTION MAKE( --
                TABLE_NAME        VARCHAR2
               ,CTRL_PACKAGE_NAME OUT VARCHAR2
               ,APP_PACKAGE_NAME  OUT VARCHAR2
                --
                ) RETURN VARCHAR2 IS
    LV_SQL_SPEC          VARCHAR2(32767);
    LV_SQL_BODY          VARCHAR2(32767);
    LV_RESULT            VARCHAR2(32767);
    LV_APP_PACKAGE_NAME  VARCHAR2(128);
    LV_CTRL_PACKAGE_NAME VARCHAR2(128);
  BEGIN
    IF TABLE_NAME IS NULL
    THEN
      LV_RESULT := '{‰«„ ÃœÊ·  ÂÌ «” }';
    ELSE
      GV_TABLENAME := TABLE_NAME;
    END IF;
    IF LV_RESULT IS NULL
    THEN
      BEGIN
        LV_CTRL_PACKAGE_NAME := UPPER(TRIM(CREATE_CTRL_PACKAGE_NAME( --
                                                                    TABLE_NAME
                                                                    --
                                                                    )));
        SELECT '{' || LV_CTRL_PACKAGE_NAME || ' «“ ﬁ»· ÊÃÊœ œ«—œ}'
          INTO LV_RESULT
          FROM DUAL
         WHERE EXISTS (SELECT NULL
                  FROM ALL_OBJECTS O
                 WHERE O.OBJECT_NAME = LV_CTRL_PACKAGE_NAME);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      IF LV_RESULT IS NULL
      THEN
        LV_SQL_SPEC := LV_SQL_SPEC ||
                       CREATE_CTRL_PACKAGE_DECLARATION( --
                                                       TABLE_NAME
                                                      ,'SPEC'
                                                       --
                                                       );
        LV_SQL_BODY := LV_SQL_BODY ||
                       CREATE_CTRL_PACKAGE_DECLARATION( --
                                                       TABLE_NAME
                                                      ,'BODY'
                                                       --
                                                       );
        --LV_SQL_BODY  := LV_SQL_BODY || CHR(10) || CREATE_GLOBAL_VARIABLES_BODY;
        --LV_SQL_SPEC  := LV_SQL_SPEC || CHR(10) || CREATE_GETTER_SETTER_SPEC;
        --LV_SQL_BODY  := LV_SQL_BODY || CHR(10) || CREATE_GETTER_SETTER_BODY;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) ||
                       CREATE_CHECK_LOCK_DECLARATION || ';';
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) ||
                       CREATE_CHECK_DATA_DECLARATION || ';';
      
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) || CREATE_CHECK_LOCK_BODY;
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) || CREATE_CHECK_DATA_BODY;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) || UPPER('end;');
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) || UPPER('end;');
        BEGIN
          EXECUTE IMMEDIATE LV_SQL_SPEC;
          EXECUTE IMMEDIATE LV_SQL_BODY;
          CTRL_PACKAGE_NAME := LV_CTRL_PACKAGE_NAME;
        EXCEPTION
          WHEN OTHERS THEN
            LV_RESULT := '{' || LV_CTRL_PACKAGE_NAME || ' Œÿ« œ«—œ}';
        END;
        --EXECUTE IMMEDIATE 'drop package apps.MAM_APP_MAKER_PKG';
        /*
        DBMS_OUTPUT.PUT_LINE(LV_SQL_SPEC);
        DBMS_OUTPUT.PUT_LINE('/');
        DBMS_OUTPUT.PUT_LINE(LV_SQL_BODY);
        */
      END IF;
    END IF;
    LV_SQL_SPEC := NULL;
    LV_SQL_BODY := NULL;
    IF LV_RESULT IS NULL
    THEN
      BEGIN
        LV_APP_PACKAGE_NAME := UPPER(TRIM(CREATE_APP_PACKAGE_NAME( --
                                                                  TABLE_NAME
                                                                  --
                                                                  )));
        SELECT '{' || LV_APP_PACKAGE_NAME || ' «“ ﬁ»· ÊÃÊœ œ«—œ}'
          INTO LV_RESULT
          FROM DUAL
         WHERE EXISTS (SELECT NULL
                  FROM ALL_OBJECTS O
                 WHERE O.OBJECT_NAME = LV_APP_PACKAGE_NAME);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      IF LV_RESULT IS NULL
      THEN
        GV_TABLENAME := TABLE_NAME;
        LV_SQL_SPEC  := LV_SQL_SPEC ||
                        CREATE_APP_PACKAGE_DECLARATION( --
                                                       TABLE_NAME
                                                      ,'SPEC'
                                                       --
                                                       );
        LV_SQL_BODY  := LV_SQL_BODY ||
                        CREATE_APP_PACKAGE_DECLARATION( --
                                                       TABLE_NAME
                                                      ,'BODY'
                                                       --
                                                       );
        --LV_SQL_BODY  := LV_SQL_BODY || CHR(10) || CREATE_GLOBAL_VARIABLES_BODY;
        --LV_SQL_SPEC  := LV_SQL_SPEC || CHR(10) || CREATE_GETTER_SETTER_SPEC;
        --LV_SQL_BODY  := LV_SQL_BODY || CHR(10) || CREATE_GETTER_SETTER_BODY;
      
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) || CREATE_ADD_DECLARATION || ';';
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) || CREATE_ADD_BODY;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) || CREATE_REMOVE_DECLARATION || ';';
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) || CREATE_REMOVE_BODY;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) || CREATE_EDIT_DECLARATION || ';';
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) || CREATE_EDIT_BODY;
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) ||
                       CREATE_CREATE_FILTER_VIEW_BODY;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) ||
                       CREATE_ADD_TO_FILTER_VIEW_DCLR || ';';
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) ||
                       CREATE_ADD_TO_FILTER_VIEW_BODY;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) ||
                       CREATE_REMOVEFROMFILTERVIW_DC || ';';
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) ||
                       CREATE_REMOVEFROMFILTERVIW_BD;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) ||
                       CREATE_DROP_FILTER_VIEW_DECLAR || ';';
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) ||
                       CREATE_DROP_FILTER_VIEW_BODY;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) ||
                       CREATE_COUNT_FILTER_RECORDS_DC || ';';
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) ||
                       CREATE_COUNT_FILTER_RECORDS_BD;
        LV_SQL_SPEC := LV_SQL_SPEC || CHR(10) || UPPER('end;');
        LV_SQL_BODY := LV_SQL_BODY || CHR(10) || UPPER('end;');
        BEGIN
          EXECUTE IMMEDIATE LV_SQL_SPEC;
          EXECUTE IMMEDIATE LV_SQL_BODY;
          APP_PACKAGE_NAME := LV_APP_PACKAGE_NAME;
        EXCEPTION
          WHEN OTHERS THEN
            LV_RESULT := '{' || LV_APP_PACKAGE_NAME || ' Œÿ« œ«—œ}';
        END;
        --EXECUTE IMMEDIATE 'drop package apps.MAM_APP_MAKER_PKG';
        /*
        DBMS_OUTPUT.PUT_LINE(LV_SQL_SPEC);
        DBMS_OUTPUT.PUT_LINE('/');
        DBMS_OUTPUT.PUT_LINE(LV_SQL_BODY);
        */
      END IF;
    END IF;
    RETURN LV_RESULT;
  END;
  FUNCTION MAKE_CTRL_SPEC_DBMS_OUTPUT( --
                                      TABLE_NAME        VARCHAR2
                                     ,CTRL_PACKAGE_NAME OUT VARCHAR2
                                      --
                                      ) RETURN VARCHAR2 IS
    LV_RESULT            VARCHAR2(1000);
    LV_CTRL_PACKAGE_NAME VARCHAR2(128);
  BEGIN
    IF TABLE_NAME IS NULL
    THEN
      LV_RESULT := '{‰«„ ÃœÊ·  ÂÌ «” }';
    ELSE
      GV_TABLENAME := TABLE_NAME;
    END IF;
    IF LV_RESULT IS NULL
    THEN
      BEGIN
        LV_CTRL_PACKAGE_NAME := UPPER(TRIM(CREATE_CTRL_PACKAGE_NAME( --
                                                                    TABLE_NAME
                                                                    --
                                                                    )));
        SELECT '{' || LV_CTRL_PACKAGE_NAME || ' «“ ﬁ»· ÊÃÊœ œ«—œ}'
          INTO LV_RESULT
          FROM DUAL
         WHERE EXISTS (SELECT NULL
                  FROM ALL_OBJECTS O
                 WHERE O.OBJECT_NAME = LV_CTRL_PACKAGE_NAME);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      IF LV_RESULT IS NULL
      THEN
        DBMS_OUTPUT.PUT_LINE(CREATE_CTRL_PACKAGE_DECLARATION( --
                                                             TABLE_NAME
                                                            ,'SPEC'
                                                             --
                                                             )
                             --
                             );
        --DBMS_OUTPUT.PUT_LINE(CREATE_GETTER_SETTER_SPEC);
        DBMS_OUTPUT.PUT_LINE(CREATE_CHECK_LOCK_DECLARATION || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_CHECK_DATA_DECLARATION || ';');
        DBMS_OUTPUT.PUT_LINE(UPPER('end;'));
        CTRL_PACKAGE_NAME := LV_CTRL_PACKAGE_NAME;
      END IF;
    END IF;
    RETURN LV_RESULT;
  END;

  FUNCTION MAKE_CTRL_BODY_DBMS_OUTPUT( --
                                      TABLE_NAME VARCHAR2
                                      --
                                      ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(1000);
  BEGIN
    IF TABLE_NAME IS NULL
    THEN
      LV_RESULT := '{‰«„ ÃœÊ·  ÂÌ «” }';
    END IF;
    IF LV_RESULT IS NULL
    THEN
      DBMS_OUTPUT.PUT_LINE(CREATE_CTRL_PACKAGE_DECLARATION( --
                                                           TABLE_NAME
                                                          ,'BODY'
                                                           --
                                                           )
                           --
                           );
      DBMS_OUTPUT.PUT_LINE(CREATE_CHECK_LOCK_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_CHECK_DATA_BODY);
      DBMS_OUTPUT.PUT_LINE(UPPER('end;'));
    END IF;
    RETURN LV_RESULT;
  END;

  FUNCTION MAKE_APP_SPEC_DBMS_OUTPUT( --
                                     TABLE_NAME       VARCHAR2
                                    ,APP_PACKAGE_NAME OUT VARCHAR2
                                     --
                                     ) RETURN VARCHAR2 IS
    LV_RESULT           VARCHAR2(1000);
    LV_APP_PACKAGE_NAME VARCHAR2(128);
  BEGIN
    IF TABLE_NAME IS NULL
    THEN
      LV_RESULT := '{‰«„ ÃœÊ·  ÂÌ «” }';
    ELSE
      GV_TABLENAME := TABLE_NAME;
    END IF;
    IF LV_RESULT IS NULL
    THEN
      BEGIN
        LV_APP_PACKAGE_NAME := UPPER(TRIM(CREATE_APP_PACKAGE_NAME( --
                                                                  TABLE_NAME
                                                                  --
                                                                  )));
        SELECT '{' || LV_APP_PACKAGE_NAME || ' «“ ﬁ»· ÊÃÊœ œ«—œ}'
          INTO LV_RESULT
          FROM DUAL
         WHERE EXISTS (SELECT NULL
                  FROM ALL_OBJECTS O
                 WHERE O.OBJECT_NAME = LV_APP_PACKAGE_NAME);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      IF LV_RESULT IS NULL
      THEN
        DBMS_OUTPUT.PUT_LINE(CREATE_APP_PACKAGE_DECLARATION( --
                                                            TABLE_NAME
                                                           ,'SPEC'
                                                            --
                                                            )
                             --
                             );
        --DBMS_OUTPUT.PUT_LINE(CREATE_GETTER_SETTER_SPEC);
        --DBMS_OUTPUT.PUT_LINE(CREATE_CHECK_DATA_DECLARATION || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_ADD_DECLARATION || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_REMOVE_DECLARATION || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_EDIT_DECLARATION || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_ADD_TO_FILTER_VIEW_DCLR || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_REMOVEFROMFILTERVIW_DC || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_DROP_FILTER_VIEW_DECLAR || ';');
        DBMS_OUTPUT.PUT_LINE(CREATE_COUNT_FILTER_RECORDS_DC || ';');
        DBMS_OUTPUT.PUT_LINE(UPPER('end;'));
        APP_PACKAGE_NAME := LV_APP_PACKAGE_NAME;
      END IF;
    END IF;
    RETURN LV_RESULT;
  END;

  FUNCTION MAKE_APP_BODY_DBMS_OUTPUT( --
                                     TABLE_NAME VARCHAR2
                                     --
                                     ) RETURN VARCHAR2 IS
    LV_RESULT            VARCHAR2(1000);
    LV_CTRL_PACKAGE_NAME VARCHAR2(128);
  BEGIN
    IF TABLE_NAME IS NULL
    THEN
      LV_RESULT := '{‰«„ ÃœÊ·  ÂÌ «” }';
    END IF;
    IF LV_RESULT IS NULL
    THEN
      DBMS_OUTPUT.PUT_LINE(CREATE_APP_PACKAGE_DECLARATION( --
                                                          TABLE_NAME
                                                         ,'BODY'
                                                          --
                                                          )
                           --
                           );
      --DBMS_OUTPUT.PUT_LINE(CREATE_GLOBAL_VARIABLES_BODY);
      --DBMS_OUTPUT.PUT_LINE(CREATE_GETTER_SETTER_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_ADD_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_REMOVE_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_EDIT_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_CREATE_FILTER_VIEW_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_ADD_TO_FILTER_VIEW_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_REMOVEFROMFILTERVIW_BD);
      DBMS_OUTPUT.PUT_LINE(CREATE_DROP_FILTER_VIEW_BODY);
      DBMS_OUTPUT.PUT_LINE(CREATE_COUNT_FILTER_RECORDS_BD);
      DBMS_OUTPUT.PUT_LINE(UPPER('end;'));
    END IF;
    RETURN LV_RESULT;
  END;

  FUNCTION MAKE_DBMS_OUTPUT( --
                            TABLE_NAME        VARCHAR2
                           ,CTRL_PACKAGE_NAME OUT VARCHAR2
                           ,APP_PACKAGE_NAME  OUT VARCHAR2
                            --
                            ) RETURN VARCHAR2 IS
    LV_RESULT VARCHAR2(1000);
  BEGIN
    IF LV_RESULT IS NULL
    THEN
      LV_RESULT := MAKE_CTRL_SPEC_DBMS_OUTPUT( --
                                              TABLE_NAME
                                             ,CTRL_PACKAGE_NAME
                                              --
                                              );
    END IF;
    IF LV_RESULT IS NULL
    THEN
      DBMS_OUTPUT.PUT_LINE('/');
      LV_RESULT := MAKE_CTRL_BODY_DBMS_OUTPUT( --
                                              TABLE_NAME
                                              --
                                              );
    END IF;
    IF LV_RESULT IS NULL
    THEN
      DBMS_OUTPUT.PUT_LINE('/');
      LV_RESULT := MAKE_APP_SPEC_DBMS_OUTPUT( --
                                             TABLE_NAME
                                            ,APP_PACKAGE_NAME
                                             --
                                             );
    END IF;
    IF LV_RESULT IS NULL
    THEN
      DBMS_OUTPUT.PUT_LINE('/');
      LV_RESULT := MAKE_APP_BODY_DBMS_OUTPUT( --
                                             TABLE_NAME
                                             --
                                             );
    END IF;
    RETURN LV_RESULT;
  END;
END;
/
