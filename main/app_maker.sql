/*
DROP FUNCTION mam_REMOVE_LAST_VOWEL_FUN;
DROP FUNCTION mam_REMOVE_VOWELS_FUN;
*/
/*
CREATE FUNCTION MAM_REMOVE_LAST_VOWEL_FUN(P_INPUT VARCHAR2)
  RETURN VARCHAR2 IS
  LV_CNTINU BOOLEAN := TRUE;
  LV_RESULT VARCHAR2(200);
  LV_INDEX  INT;
BEGIN
  LV_RESULT := P_INPUT;
  LV_INDEX  := LENGTH(LV_RESULT) - 1;
  IF (LENGTH(LV_RESULT) > 2) THEN
    LOOP
      IF (UPPER(SUBSTR(LV_RESULT, LV_INDEX, 1)) IN
         ('A', 'E', 'I', 'O', 'U')) THEN
        LV_RESULT := SUBSTR(LV_RESULT, 1, LV_INDEX - 1) ||
                     SUBSTR(LV_RESULT, LV_INDEX + 1, LENGTH(LV_RESULT));
        LV_CNTINU := FALSE;
      END IF;
      LV_INDEX := LV_INDEX - 1;
      IF (LV_INDEX < 2) THEN
        LV_CNTINU := FALSE;
      END IF;
      EXIT WHEN NOT LV_CNTINU;
    END LOOP;
  END IF;
  RETURN LV_RESULT;
END;
/
CREATE FUNCTION MAM_REMOVE_VOWELS_FUN
(
  P_INPUT         VARCHAR2
 ,P_RESULT_LENGTH INT
) RETURN VARCHAR2 IS
  LV_CNTINU BOOLEAN;
  LV_RESULT VARCHAR2(200);
  LV_TMP    VARCHAR2(200);
BEGIN
  LV_RESULT := P_INPUT;
  IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1) THEN
    LV_CNTINU := FALSE;
  ELSE
    LV_CNTINU := TRUE;
  END IF;
  WHILE LV_CNTINU
  LOOP
    LV_TMP := MAM_REMOVE_LAST_VOWEL_FUN(LV_RESULT);
    --DBMS_OUTPUT.PUT_LINE(LV_TMP);
    IF (LV_TMP = LV_RESULT) THEN
      LV_CNTINU := FALSE;
    ELSE
      LV_RESULT := LV_TMP;
    END IF;
    IF (LENGTH(LV_RESULT) < P_RESULT_LENGTH + 1) THEN
      LV_CNTINU := FALSE;
    END IF;
  END LOOP;
  RETURN LV_RESULT;
END;
*/
----------------------------------------------------------------------------
DECLARE
  LV_TABLENAME    VARCHAR2(100) := UPPER(TRIM('&TABLENAME'));
  DELIMITTER      VARCHAR2(20);
  I               NUMBER;
  LV_PACKAGE_NAME VARCHAR2(100);
  /*
    CURSOR TABLENAME IS
      SELECT T.TABLE_NAME AS TABLENAME
        FROM ALL_TABLES T
       WHERE T.TABLE_NAME LIKE UPPER('mam%')
       ORDER BY T.TABLE_NAME;
  */
  CURSOR TABLE_COLUMNS IS
    SELECT TC.TABLE_NAME
          ,TC.COLUMN_NAME
          ,CASE
             WHEN TC.DATA_TYPE IN ('NUMBER', 'DATE')
                  AND CC.TABLE_NAME IS NULL THEN
              1
             ELSE
              0
           END AS SUBJECT_OF_FROM_TO
          ,UPPER('P_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 28)) AS PARAMETER_NAME
          ,UPPER('SET_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 26)) AS SETTER_NAME
          ,UPPER('SET_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 21) ||
                 '_FROM') AS SETTER_FROM_NAME
          ,UPPER('SET_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 23) ||
                 '_TO') AS SETTER_TO_NAME
          ,UPPER('GET_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 26)) AS GETTER_NAME
          ,UPPER('GET_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 21) ||
                 '_FROM') AS GETTER_FROM_NAME
          ,UPPER('GET_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 23) ||
                 '_TO') AS GETTER_TO_NAME
          ,UPPER('gV_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 27)) AS GLOBAL_VARIABLE_NAME
          ,UPPER('gV_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 22) ||
                 '_FROM') AS GLOBAL_FROM_VARIABLE_NAME
          ,UPPER('gV_' || MAM_REMOVE_VOWELS_FUN(TC.COLUMN_NAME, 24) ||
                 '_TO') AS GLOBAL_TO_VARIABLE_NAME
          ,TC.DATA_TYPE
          ,TC.DATA_LENGTH
          ,PK.IS_PK
          ,CASE
             WHEN CC.TABLE_NAME IS NULL THEN
              0
             ELSE
              1
           END AS IS_ON_FK
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
     WHERE UPPER(TC.TABLE_NAME) = UPPER(LV_TABLENAME)
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
                                      --,''
                                      )
     ORDER BY PK.IS_PK
             ,TC.COLUMN_ID;

BEGIN
  DBMS_OUTPUT.ENABLE(1000000);
  LV_TABLENAME    := UPPER(LV_TABLENAME);
  LV_PACKAGE_NAME := 'APP_' ||
                     UPPER(MAM_REMOVE_VOWELS_FUN(LV_TABLENAME, 22)) ||
                     '_PKG';
  --*********************************************************************
  DBMS_OUTPUT.PUT_LINE('CREATE PACKAGE ' || LV_PACKAGE_NAME || ' IS');
  DBMS_OUTPUT.PUT_LINE('');
  --GETTER_AND_SETTER
  I := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE('-- GETTER AND SETTER FOR ' || C.COLUMN_NAME ||
                         ' --------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || C.SETTER_NAME || '(' ||
                         C.PARAMETER_NAME || ' ' || C.TABLE_NAME || '.' ||
                         C.COLUMN_NAME || '%TYPE);--' || TO_CHAR(I) || '--');
    IF (C.SUBJECT_OF_FROM_TO = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || C.SETTER_FROM_NAME || '(' ||
                           C.PARAMETER_NAME || ' ' || C.TABLE_NAME || '.' ||
                           C.COLUMN_NAME || '%TYPE);--' || TO_CHAR(I) || '--');
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || C.SETTER_TO_NAME || '(' ||
                           C.PARAMETER_NAME || ' ' || C.TABLE_NAME || '.' ||
                           C.COLUMN_NAME || '%TYPE);--' || TO_CHAR(I) || '--');
    END IF;
    DBMS_OUTPUT.PUT_LINE('FUNCTION ' || C.GETTER_NAME || ' RETURN ' ||
                         C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                         '%TYPE;--' || TO_CHAR(I) || '--');
    IF (C.SUBJECT_OF_FROM_TO = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE('FUNCTION ' || C.GETTER_FROM_NAME || ' RETURN ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                           '%TYPE;--' || TO_CHAR(I) || '--');
      DBMS_OUTPUT.PUT_LINE('FUNCTION ' || C.GETTER_TO_NAME || ' RETURN ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                           '%TYPE;--' || TO_CHAR(I) || '--');
    END IF;
    I := I + 1;
  END LOOP;
  --CHECK_DATA
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION CHECK_DATA --------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION CHECK_DATA(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                         C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(') RETURN VARCHAR2;');
  --ADD
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION ADD -------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION ADD(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                         --
                         CASE
                           WHEN C.IS_PK = 1 THEN
                            'IN OUT '
                         END ||
                         --
                         C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(')RETURN VARCHAR2;');
  --REMOVE
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION REMOVE-----------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION REMOVE(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    IF (C.IS_PK = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                           TO_CHAR(I) || '--');
      DELIMITTER := ', ';
    END IF;
    I := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(') RETURN VARCHAR2;');
  --EDIT
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION EDIT -------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION EDIT(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                         --
                         CASE
                           WHEN C.IS_PK = 1 THEN
                            'IN OUT '
                         END ||
                         --
                         C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(')RETURN VARCHAR2;');
  --

  DBMS_OUTPUT.PUT_LINE('END;'); --of pkg
  DBMS_OUTPUT.PUT_LINE('/'); --of pkg
  --************************Body*********************************************
  DBMS_OUTPUT.PUT_LINE('CREATE PACKAGE BODY ' || LV_PACKAGE_NAME || ' IS');
  DBMS_OUTPUT.PUT_LINE('');
  --local_variable
  DBMS_OUTPUT.PUT_LINE('-- LOCAL VARIABLES --------------------------------------');
  I := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(C.GLOBAL_VARIABLE_NAME || ' ' || C.TABLE_NAME || '.' ||
                         C.COLUMN_NAME || '%TYPE;--' || TO_CHAR(I) || '--');
    IF (C.SUBJECT_OF_FROM_TO = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE(C.GLOBAL_FROM_VARIABLE_NAME || ' ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                           '%TYPE;--' || TO_CHAR(I) || '--');
      DBMS_OUTPUT.PUT_LINE(C.GLOBAL_TO_VARIABLE_NAME || ' ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                           '%TYPE;--' || TO_CHAR(I) || '--');
    END IF;
    I := I + 1;
  END LOOP;
  --GETTER_AND_SETTER
  I := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE('-- GETTER AND SETTER FOR ' || C.COLUMN_NAME ||
                         ' --------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || C.SETTER_NAME || '(' ||
                         C.PARAMETER_NAME || ' ' || C.TABLE_NAME || '.' ||
                         C.COLUMN_NAME || '%TYPE) IS --' || TO_CHAR(I) || '--');
    DBMS_OUTPUT.PUT_LINE('BEGIN');
    DBMS_OUTPUT.PUT_LINE(C.GLOBAL_VARIABLE_NAME || ':=' ||
                         C.PARAMETER_NAME || ';');
    DBMS_OUTPUT.PUT_LINE('END;');
    IF (C.SUBJECT_OF_FROM_TO = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || C.SETTER_FROM_NAME || '(' ||
                           C.PARAMETER_NAME || ' ' || C.TABLE_NAME || '.' ||
                           C.COLUMN_NAME || '%TYPE) IS --' || TO_CHAR(I) || '--');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE(C.GLOBAL_FROM_VARIABLE_NAME || ':=' ||
                           C.PARAMETER_NAME || ';');
      DBMS_OUTPUT.PUT_LINE('END;');
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || C.SETTER_TO_NAME || '(' ||
                           C.PARAMETER_NAME || ' ' || C.TABLE_NAME || '.' ||
                           C.COLUMN_NAME || '%TYPE) IS --' || TO_CHAR(I) || '--');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE(C.GLOBAL_TO_VARIABLE_NAME || ':=' ||
                           C.PARAMETER_NAME || ';');
      DBMS_OUTPUT.PUT_LINE('END;');
    END IF;
    DBMS_OUTPUT.PUT_LINE('FUNCTION ' || C.GETTER_NAME || ' RETURN ' ||
                         C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                         '%TYPE IS--' || TO_CHAR(I) || '--');
    DBMS_OUTPUT.PUT_LINE('BEGIN');
    DBMS_OUTPUT.PUT_LINE('RETURN ' || C.GLOBAL_VARIABLE_NAME || ';');
    DBMS_OUTPUT.PUT_LINE('END;');
    IF (C.SUBJECT_OF_FROM_TO = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE('FUNCTION ' || C.GETTER_FROM_NAME || ' RETURN ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                           '%TYPE IS--' || TO_CHAR(I) || '--');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE('RETURN ' || C.GLOBAL_FROM_VARIABLE_NAME || ';');
      DBMS_OUTPUT.PUT_LINE('END;');
    
      DBMS_OUTPUT.PUT_LINE('FUNCTION ' || C.GETTER_TO_NAME || ' RETURN ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME ||
                           '%TYPE IS--' || TO_CHAR(I) || '--');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE('RETURN ' || C.GLOBAL_TO_VARIABLE_NAME || ';');
      DBMS_OUTPUT.PUT_LINE('END;');
    END IF;
    I := I + 1;
  END LOOP;
  --CHECK_DATA
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION CHECK_DATA --------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION CHECK_DATA(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                         C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(') RETURN VARCHAR2 IS');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT VARCHAR2(1000):='''';');
  DBMS_OUTPUT.PUT_LINE('BEGIN');
  DBMS_OUTPUT.PUT_LINE('RETURN LV_RESULT;');
  DBMS_OUTPUT.PUT_LINE('END;');
  --ADD
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION ADD -------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION ADD(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                         --
                         CASE
                           WHEN C.IS_PK = 1 THEN
                            'IN OUT '
                         END ||
                         --
                         C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(')RETURN VARCHAR2 IS');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT VARCHAR2(1000):='''';');
  DBMS_OUTPUT.PUT_LINE('BEGIN');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT:=CHECK_DATA(--');
  -- <parameters to check
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters to check>
  DBMS_OUTPUT.PUT_LINE(');');
  DBMS_OUTPUT.PUT_LINE('IF (LV_RESULT IS NULL) THEN');
  DBMS_OUTPUT.PUT_LINE('BEGIN');
  DBMS_OUTPUT.PUT_LINE('INSERT INTO ' || LV_TABLENAME);
  DBMS_OUTPUT.PUT_LINE('(');
  -- <insert fields
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.COLUMN_NAME || '--' || TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --insert fields>
  DBMS_OUTPUT.PUT_LINE(')');
  DBMS_OUTPUT.PUT_LINE('VALUES');
  DBMS_OUTPUT.PUT_LINE('(');
  -- <insert parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --insert parameters>
  DBMS_OUTPUT.PUT_LINE(');');
  DBMS_OUTPUT.PUT_LINE('EXCEPTION');
  DBMS_OUTPUT.PUT_LINE(' WHEN OTHERS THEN ');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT := ''{رکوردی در جدول درج نشد}'';');
  DBMS_OUTPUT.PUT_LINE('END;');
  DBMS_OUTPUT.PUT_LINE('END IF;');
  DBMS_OUTPUT.PUT_LINE('RETURN LV_RESULT;');
  DBMS_OUTPUT.PUT_LINE('END;');
  --

  --REMOVE
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION REMOVE-----------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION REMOVE(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    IF (C.IS_PK = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                           C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                           TO_CHAR(I) || '--');
      DELIMITTER := ', ';
    END IF;
    I := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(') RETURN VARCHAR2 IS');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT VARCHAR2(1000):='''';');
  DBMS_OUTPUT.PUT_LINE('BEGIN');
  DBMS_OUTPUT.PUT_LINE('BEGIN');
  DBMS_OUTPUT.PUT_LINE('DELETE ' || LV_TABLENAME || ' WHERE ');
  -- <REMOVE parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    IF (C.IS_PK = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.COLUMN_NAME || '=');
      DBMS_OUTPUT.PUT_LINE(C.PARAMETER_NAME || '--' || TO_CHAR(I) || '--');
      DELIMITTER := ' AND ';
    END IF;
    I := I + 1;
  END LOOP;
  --REMOVE parameters>
  DBMS_OUTPUT.PUT_LINE(';');
  DBMS_OUTPUT.PUT_LINE('EXCEPTION');
  DBMS_OUTPUT.PUT_LINE(' WHEN OTHERS THEN ');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT := ''{به دلیل استفاده از رکورد در دیگر جداول، حذف آن امکانپذیر نیست}'';');
  DBMS_OUTPUT.PUT_LINE('END;');
  DBMS_OUTPUT.PUT_LINE('RETURN LV_RESULT;');
  DBMS_OUTPUT.PUT_LINE('END;');
  --

  --EDIT
  DBMS_OUTPUT.PUT_LINE('-- FUNCTION EDIT -------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('FUNCTION EDIT(--');
  -- <parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || ' ' ||
                         --
                         CASE
                           WHEN C.IS_PK = 1 THEN
                            'IN OUT '
                         END ||
                         --
                         C.TABLE_NAME || '.' || C.COLUMN_NAME || '%TYPE' || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters>
  DBMS_OUTPUT.PUT_LINE(')RETURN VARCHAR2 IS');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT VARCHAR2(1000):='''';');
  DBMS_OUTPUT.PUT_LINE('BEGIN');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT:=CHECK_DATA(');
  -- <parameters to check
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.PARAMETER_NAME || '--' ||
                         TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --parameters to check>
  DBMS_OUTPUT.PUT_LINE(');');
  DBMS_OUTPUT.PUT_LINE('IF (LV_RESULT IS NULL) THEN');
  DBMS_OUTPUT.PUT_LINE('BEGIN');
  DBMS_OUTPUT.PUT_LINE('UPDATE ' || LV_TABLENAME || ' SET ');
  -- <edit fields
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.COLUMN_NAME || '=' ||
                         C.PARAMETER_NAME || '--' || TO_CHAR(I) || '--');
    DELIMITTER := ', ';
    I          := I + 1;
  END LOOP;
  --edit fields>
  DBMS_OUTPUT.PUT_LINE(' WHERE ');
  -- <edit parameters
  DELIMITTER := '';
  I          := 1;
  FOR C IN TABLE_COLUMNS
  LOOP
    IF (C.IS_PK = 1)
    THEN
      DBMS_OUTPUT.PUT_LINE(DELIMITTER || C.COLUMN_NAME || '=');
      DBMS_OUTPUT.PUT_LINE(C.PARAMETER_NAME || '--' || TO_CHAR(I) || '--');
      DELIMITTER := ' AND ';
    END IF;
    I := I + 1;
  END LOOP;
  --edit parameters>
  DBMS_OUTPUT.PUT_LINE(';');
  DBMS_OUTPUT.PUT_LINE('EXCEPTION');
  DBMS_OUTPUT.PUT_LINE(' WHEN OTHERS THEN ');
  DBMS_OUTPUT.PUT_LINE('LV_RESULT := ''{تغییری در رکورد صورت نگرفت}'';');
  DBMS_OUTPUT.PUT_LINE('END;');
  DBMS_OUTPUT.PUT_LINE('END IF;');
  DBMS_OUTPUT.PUT_LINE('RETURN LV_RESULT;');
  DBMS_OUTPUT.PUT_LINE('END;');
  --

  DBMS_OUTPUT.PUT_LINE('END;'); --of pkg
END;
