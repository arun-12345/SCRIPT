--------------------------------------------------------
--  File created - Monday-February-11-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure GENERATE_CCPAP_FILE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "GENERATE_CCPAP_FILE" (
    FROMDATE   IN VARCHAR2,
    TODATE     IN VARCHAR2,
    FILENAME   OUT VARCHAR2,
    KEY        OUT VARCHAR2
) IS
/*
-----------------------CHANGES TO INCORPORATE FUNCTION BANK_TYPE----------------------------------------------------------
-----------------------CHANGES AS PER DIRECTION OF SMT SHANTHI SHIVRAM-----------------------------------------------------
-----------------------TO IMPLEMENT CHANGES FOR REGIONAL RURAL BANKS OF SBI------------------------------------------------
*/
    XML             UTL_FILE.FILE_TYPE;
    FP              UTL_FILE.FILE_TYPE;
    HTML            UTL_FILE.FILE_TYPE;
    EID             VARCHAR2(50);
    TOT             NUMBER := 0;
    TOTAMT          NUMBER := 0;
    FDT             DATE := TO_DATE(FROMDATE,'dd/mm/yyyy');
    TDT             DATE := TO_DATE(TODATE,'dd/mm/yyyy');
    FROMDT          NUMBER := TO_CHAR(FDT,'yyyymmdd');
    BLANK_COND      BOOLEAN;
    BLANK_CNT       NUMBER := 0;
    LAC             VARCHAR2(2);
    NUM             NUMBER := 2;
    OFC             VARCHAR2(3);
    FNAME           VARCHAR2(1000);
    SEP             VARCHAR2(1) := CHR(9);
    REC             VARCHAR2(2000);
    FMT             VARCHAR2(15) := '99999,99,99999';
    AC              VARCHAR2(11);
    BCODE           VARCHAR2(6);
    AC_NO           NUMBER;
    GTOT            NUMBER := 0;
    GTOTAMT         NUMBER := 0;
    ONAME           VARCHAR2(5);
    NEFT_CBS_AMT    NUMBER := 0;
    NEFT_CBS_CNT    NUMBER := 0;
    NEFT_CBS_TAMT   NUMBER := 0;
    NEFT_CBS_TCNT   NUMBER := 0;
    BGL             VARCHAR2(17);
    CBS_GAMT        NUMBER := 0;
    CBS_GCNT        NUMBER := 0;
    NEFT_GAMT       NUMBER := 0;
    NEFT_GCNT       NUMBER := 0;
    SL              NUMBER := 0;
    GCNT            NUMBER;
    GAMT            NUMBER;
    CBS_TXT         UTL_FILE.FILE_TYPE;
    CBS_HTML        UTL_FILE.FILE_TYPE;
    CBS_XML         UTL_FILE.FILE_TYPE;
    NEFT_HTML       UTL_FILE.FILE_TYPE;
    NEFT_XML        UTL_FILE.FILE_TYPE;
    CCDIR           VARCHAR2(200);
    NEFTDIR         VARCHAR2(200);

    FUNCTION CSV2HTML (
        SRC   IN VARCHAR2,
        HDR   IN VARCHAR2 DEFAULT 'N',
        SP    IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2 AS

        ST1   VARCHAR2(50) := ( CASE
            WHEN HDR = 'N' THEN '<td>'
            ELSE '<th>'
        END );
        ST2   VARCHAR2(50) := ( CASE
            WHEN HDR = 'N' THEN '</td>'
            ELSE '</th>'
        END );
    BEGIN
        RETURN '<tr align=right>'
               || ST1
               || REPLACE(SRC,SP,ST2 || ST1)
               || ST2
               || '</tr>';
    END CSV2HTML;

BEGIN
    SELECT
        COUNT(*)
    INTO TOT
    FROM
        EPFO_BANK_DETAILS
    WHERE
        EPF_ACCOUNT_NO IN (
            1,
            2,
            10,
            21
        )
        AND REGEXP_LIKE ( BANK_ACCOUNT_NO || BRANCH_CODE,
                          '[^0-9]+' );

    IF TOT = 0 AND FROMDATE IS NOT NULL THEN
        BEGIN
            SELECT
                OFFICE_ID,
                REGION_CODE || ACC_OFF_ID,
                EMAILID
            INTO
                OFC,
                ONAME,
                EID
            FROM
                EPFO_OFF_MASTER
            WHERE
                RECORD_STATUS = 0
                AND SLIP_TYPE = '600';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                OFC := '999';
                ONAME := '';
                EID := '';
        END;

        BEGIN
            SELECT
                LPAD(TRIM(BGL_ACCOUNT),17,0)
            INTO BGL
            FROM
                PAYMENT_COMMISSION_MASTER
            WHERE
                PAYMENT_MODE = 'N';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BGL := '';
        END;

        BEGIN
            SELECT
                DIRECTORY_PATH
            INTO CCDIR
            FROM
                ALL_DIRECTORIES
            WHERE
                UPPER(DIRECTORY_NAME) = 'CCPAP_DIR';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                CCDIR := '/image/ExtTableData/CCPAP/';
        END;

        CCDIR := CCDIR
                 || CASE
            WHEN SUBSTR(CCDIR,-1) = '/' THEN ''
            ELSE '/'
        END;

        BEGIN
            SELECT
                DIRECTORY_PATH
            INTO NEFTDIR
            FROM
                ALL_DIRECTORIES
            WHERE
                UPPER(DIRECTORY_NAME) = 'NEFT_DIR';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NEFTDIR := '/image/NEFTFolder/';
        END;

        NEFTDIR := NEFTDIR
                   || CASE
            WHEN SUBSTR(NEFTDIR,-1) = '/' THEN ''
            ELSE '/'
        END;

        IF OFC <> '999' THEN
            NUM :=
                CASE
                    WHEN TDT >= '10-mar-2016' THEN 4
                    ELSE 3
                END;
            SELECT
                COUNT(*),
                SUM(CHEQUE_AMOUNT)
            INTO
                GTOT,
                GTOTAMT
            FROM
                CHEQUE_DETAILS
            WHERE
                ( EPFO_ACCOUNT_NO IN (
                    1,
                    10,
                    21
                )
                  OR ( EPFO_ACCOUNT_NO = 2
                       AND NUM = 4 ) )
                AND CHEQUE_NO <> '9999999999'
                AND SLIP_TYPE = '600'
                AND CHEQUE_DATE >= ADD_MONTHS(TDT,-3)
                AND CHEQUE_AMOUNT > 0
                AND ( DISPATCH_DATE BETWEEN FDT AND TDT
                      OR ( TO_CHAR(DISPATCH_DATE,'yyyymmdd') + 20000000 >= FROMDT
                           AND TO_CHAR(DISPATCH_DATE,'yyyy') = '0014' ) );

        END IF;

    END IF;

    IF GTOT > 0 AND GTOTAMT > 0 THEN
        FOR I IN 1..NUM LOOP
            AC_NO :=
                CASE I
                    WHEN 4 THEN 2
                    WHEN 3 THEN 21
                    WHEN 2 THEN 10
                    ELSE 1
                END;

            LAC := LPAD(AC_NO,2,0);
            BEGIN
                SELECT
                    LPAD(TO_NUMBER(BANK_ACCOUNT_NO),11,0),
                    LPAD(TO_NUMBER(BRANCH_CODE),6,0)
                INTO
                    AC,
                    BCODE
                FROM
                    EPFO_BANK_DETAILS
                WHERE
                    EPF_ACCOUNT_NO = AC_NO;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    AC := 'xx';
                    BCODE := 'xxxx';
            END;

            IF I = 1 THEN
                FNAME := 'CCPAP_'
                         || OFC
                         || '_'
                         || ONAME
                         || '_'
                         || BCODE
                         || '_'
                         || TO_CHAR(TDT,'yyyy-mm-dd')
                         || '_'
                         || TO_CHAR(FDT,'yyyy-mm-dd');

                XML := UTL_FILE.FOPEN('CCPAP_DIR',FNAME || '.dat','W',32767);

                FP := UTL_FILE.FOPEN('CCPAP_DIR',FNAME || '.xls','W',32767);

                HTML := UTL_FILE.FOPEN('CCPAP_DIR',FNAME || '.html','W',32767);

                REC :=
                    CASE
                        WHEN FDT = TDT THEN ' ON ' || FDT
                        ELSE ' FROM '
                             || FDT
                             || ' TO '
                             || TDT
                    END;

                REC := 'LIST OF CHEQUES DISPATCHED'
                       || REC
                       || ' AND ISSUED FROM A/Cs. 01, 02, 10 and 21';
                UTL_FILE.PUT_LINE(FP,REC);
                UTL_FILE.PUT_LINE(HTML,'<!DOCTYPE html><html><head><title>CCPAP ADVISE FILE LISTING FOR VERIFICATION PURPOSES OF CHEQUE DISPATCHER AND APPROVER BEFORE APPROVING</title>'
                );
                UTL_FILE.PUT_LINE(HTML,'<meta http-equiv="cache-control" content="max-age=0" /><meta http-equiv="cache-control" content="no-cache" /><meta http-equiv="expires" content="0" /><meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" /><meta http-equiv="pragma" content="no-cache" />'
                );
                UTL_FILE.PUT_LINE(HTML,'</head><body><table border=1><caption><b>'
                                         || REC
                                         || '<br>NOTE: Please ensure that all cheques (including Manual cheques) issued by this office are included in the list</br></b></caption>'
                                         );
                REC := 'Sl'
                       || SEP
                       || 'A/c'
                       || SEP
                       || 'Cheque No'
                       || SEP
                       || 'Cheque Date'
                       || SEP
                       || 'Amount'
                       || SEP
                       || 'Beneficiary Name'
                       || SEP
                       || 'Claim ID'
                       || SEP
                       || 'Scroll No./Summry Sheet No./Remarks'
                       || SEP
                       || 'Dispatch Date';

                UTL_FILE.PUT_LINE(FP,REC);
                UTL_FILE.PUT_LINE(HTML,CSV2HTML(REC,'Y',SEP) );
                UTL_FILE.PUT_LINE(XML,'<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
                UTL_FILE.PUT_LINE(XML,'<CCPAP_DATA>');
                UTL_FILE.PUT_LINE(XML,' <DATA>');
                UTL_FILE.PUT_LINE(XML,'  <HEADER>');
                UTL_FILE.PUT_LINE(XML,'   <TOTALITEMS>'
                                        || LPAD(GTOT,6,0)
                                        || '</TOTALITEMS>'
                                        || '<TOTALAMOUNT>'
                                        || LPAD(GTOTAMT,14,0)
                                        || '000</TOTALAMOUNT><DESCRIPTION>'
                                        || RPAD(FNAME,50)
                                        || '</DESCRIPTION>');

                UTL_FILE.PUT_LINE(XML,'  </HEADER>');
                UTL_FILE.PUT_LINE(XML,'  <DETAILS>');
                FNAME := CCDIR
                         || FNAME
                         || '#dat,xls,html';
            END IF;

            TOT := 0;
            TOTAMT := 0;
            FOR X IN (
                SELECT
                    CD.CHEQUE_AMOUNT,
                    TRIM(CD.CHEQUE_NO) AS CHQ,
                    CD.CHEQUE_DATE,
                    CD.PAYEE_NAME,
                    CD.DISPATCH_DATE,
                    CD.CLAIM_ID,
                    CD.SCROLL_NO,
                    CD.MISC_PAYM_FLAG,
                    CD.CREATED_REMARKS,
                    CD.SUMMARY_SHEET_NO,
                    CD.RMO_DATE,
                    ( PCD.PARA_CODE
                      || ':'
                      || PCD.SUB_PARA ) AS CTYPE,
                    CD.ACCOUNT_NO
                FROM
                    CHEQUE_DETAILS CD
                    LEFT JOIN PAYMENT_CLAIM_DETAILS PCD ON PCD.CLAIM_ID = CD.CLAIM_ID
                WHERE
                    CD.EPFO_ACCOUNT_NO = AC_NO
                    AND CD.CHEQUE_NO <> '9999999999'
                    AND CD.CHEQUE_AMOUNT > 0
                    AND ( CD.DISPATCH_DATE BETWEEN FDT AND TDT
                          OR ( TO_CHAR(CD.DISPATCH_DATE,'yyyymmdd') + 20000000 >= FROMDT
                               AND TO_CHAR(CD.DISPATCH_DATE,'yyyy') = '0014' ) )
                    AND CD.SLIP_TYPE = '600'
                    AND CD.CHEQUE_DATE >= ADD_MONTHS(TDT,-3)
                ORDER BY
                    CD.CHEQUE_DATE,
                    CD.CHEQUE_NO
            ) LOOP
                TOT := TOT + 1;
                TOTAMT := TOTAMT + X.CHEQUE_AMOUNT;
                REC := TRIM(X.PAYEE_NAME);
                BLANK_COND := ( REC IS NULL );
                BLANK_CNT := BLANK_CNT + (
                    CASE
                        WHEN BLANK_COND THEN 1
                        ELSE 0
                    END
                );
                REC :=
                    CASE
                        WHEN BLANK_COND AND X.CLAIM_ID IS NULL THEN ( CASE
                            WHEN INSTR(NVL(X.SUMMARY_SHEET_NO,'X'),'/N/') > 0 THEN 'STATE BANK OF INDIA'
                            WHEN INSTR(NVL(X.SUMMARY_SHEET_NO,'X'),'/M/') > 0 THEN 'POST MASTER'
                        END )
                        WHEN LENGTH(REC) > 50 THEN SUBSTR(REC,50)
                        ELSE REC
                    END;

                UTL_FILE.PUT_LINE(XML,'   <RECORD><ACCOUNTNUMBER>'
                                        || LPAD(AC,17,0)
                                        || '</ACCOUNTNUMBER><AMOUNT>'
                                        || LPAD(X.CHEQUE_AMOUNT,14,0)
                                        || '000</AMOUNT><CHEQUENO>'
                                        || LPAD(TO_NUMBER(X.CHQ),6,0)
                                        || '</CHEQUENO><TRANDATE>'
                                        || TO_CHAR(TDT,'ddmmyyyy')
                                        || '</TRANDATE><BENNAME>'
                                        || RPAD(REC,50)
                                        || '</BENNAME><WARRANT>'
                                        || LPAD(0,16,0)
                                        || '</WARRANT><PAYDATE>'
                                        || TO_CHAR(X.CHEQUE_DATE,'ddmmyyyy')
                                        || '</PAYDATE><INSTRUMENT>29</INSTRUMENT></RECORD>');

                REC := TOT
                       || SEP
                       || LAC
                       || SEP
                       || X.CHQ
                       ||
                    CASE
                        WHEN X.RMO_DATE IS NOT NULL THEN '*'
                    END
                       || SEP
                       || TO_CHAR(X.CHEQUE_DATE,'dd-mm-yyyy')
                       || SEP
                       || REPLACE(TO_CHAR(X.CHEQUE_AMOUNT,FMT),' ')
                       || SEP
                       || REC
                       ||
                    CASE
                        WHEN BLANK_COND THEN '#'
                    END
                       || SEP
                       ||
                    CASE
                        WHEN X.CLAIM_ID IS NULL THEN 'NEFT/BULK PAYMENT'
                        ELSE X.CLAIM_ID
                    END
                       || SEP
                       || (
                    CASE
                        WHEN NVL(X.MISC_PAYM_FLAG,'N') = 'Y' THEN X.CREATED_REMARKS
                        WHEN X.SCROLL_NO IS NULL THEN X.SUMMARY_SHEET_NO
                        ELSE X.SCROLL_NO
                    END
                )
                       ||
                    CASE
                        WHEN X.CTYPE != ':' THEN ';' || X.CTYPE
                        ELSE ''
                    END
                       || ';A/c No.'
                       || X.ACCOUNT_NO
                       || SEP
                       || TO_CHAR(X.DISPATCH_DATE,'dd-mm-yyyy');

                UTL_FILE.PUT_LINE(FP,REC);
                UTL_FILE.PUT_LINE(HTML,CSV2HTML(REC,'N',SEP) );
                IF BGL IS NOT NULL AND I < 3 AND FDT = TDT AND X.CLAIM_ID IS NULL AND INSTR(NVL(X.SUMMARY_SHEET_NO,'X'),'/N/') > 0
                THEN
                    SELECT
                        SUM(TRAN_AMOUNT),
                        COUNT(BENEFICIARY_ACCT_NO)
                    INTO
                        NEFT_CBS_TAMT,
                        NEFT_CBS_TCNT
                    FROM
                        NEFT_PAYMENT
                    WHERE
                        SUMMARY_SHEET_NO = X.SUMMARY_SHEET_NO
                        AND SLIP_TYPE = '600'
                        AND RECORD_STATUS = 0
                        AND CHEQUE_NO = X.CHQ;

                    IF X.CHEQUE_AMOUNT = NEFT_CBS_TAMT THEN
                        SELECT
                            SUM(TRAN_AMOUNT),
                            COUNT(BENEFICIARY_ACCT_NO)
                        INTO
                            NEFT_CBS_AMT,
                            NEFT_CBS_CNT
                        FROM
                            NEFT_PAYMENT
                        WHERE
                            SUMMARY_SHEET_NO = X.SUMMARY_SHEET_NO
                            AND RECIEVER_BANK_IFSC_CODE LIKE '%SBIN%'
                            AND SLIP_TYPE = '600'
                            AND RECORD_STATUS = 0
                            AND CHEQUE_NO = X.CHQ;

                        IF NEFT_CBS_AMT > 0 AND NEFT_CBS_CNT > 0 THEN
                            REC := 'CBS_'
                                   || OFC
                                   || '_'
                                   || ONAME
                                   || '_'
                                   || BCODE
                                   || '_'
                                   || TO_CHAR(TDT,'yyyy-mm-dd');

                            CBS_TXT := UTL_FILE.FOPEN('CCPAP_DIR',REC
                                                                    || '.'
                                                                    || LAC,'W',32767);

                            IF CBS_GAMT = 0 AND CBS_GCNT = 0 THEN
                                FNAME := FNAME
                                         || '@'
                                         || CCDIR
                                         || REC
                                         || '#dat,html,01,10';
                                CBS_HTML := UTL_FILE.FOPEN('CCPAP_DIR',REC || '.html','W',32767);

                                UTL_FILE.PUT_LINE(CBS_HTML,'<!DOCTYPE html><html><head><title>SBI CBS PAYMENTS</title>');
                                UTL_FILE.PUT_LINE(CBS_HTML,'<meta http-equiv="cache-control" content="max-age=0" /><meta http-equiv="cache-control" content="no-cache" /><meta http-equiv="expires" content="0" /><meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" /><meta http-equiv="pragma" content="no-cache" />'
                                );
                                UTL_FILE.PUT_LINE(CBS_HTML,'</head><body><table border=1><thead><b><center>LIST OF SBI(CBS) PAYMENT MADE TO CLAIMANTS HAVING ACCOUNTS WITH SBI<br>CHEQUE DISPATCH DATE:'
                                                             || UPPER(FROMDATE)
                                                             || '</br></center></b></thead>');
                                UTL_FILE.PUT_LINE(CBS_HTML,CSV2HTML('A/c.'
                                                                        || SEP
                                                                        || 'Sl'
                                                                        || SEP
                                                                        || 'Scroll'
                                                                        || SEP
                                                                        || 'PID'
                                                                        || SEP
                                                                        || 'Claim id'
                                                                        || SEP
                                                                        || 'Name of the Claimant'
                                                                        || SEP
                                                                        || 'Bank A/c No.'
                                                                        || SEP
                                                                        || 'IFSC Code'
                                                                        || SEP
                                                                        || 'Amount'
                                                                        || SEP
                                                                        || 'Para','Y',SEP) );

                                CBS_XML := UTL_FILE.FOPEN('CCPAP_DIR',REC || '.dat','W',32767);

                                UTL_FILE.PUT_LINE(CBS_XML,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><DATA><CBS_DATA><HEADER>'

                                );
                                UTL_FILE.PUT_LINE(CBS_XML,'<HDR_FLAG>54</HDR_FLAG><BGL_ACNO>'
                                                            || BGL
                                                            || '</BGL_ACNO><TOTALAMOUNT>'
                                                            || LPAD(GAMT,14,0)
                                                            || '00</TOTALAMOUNT><TOTALITEMS>'
                                                            || LPAD(GCNT,6,0)
                                                            || '</TOTALITEMS><DESCRIPTION>'
                                                            || RPAD(REC,60)
                                                            || '</DESCRIPTION></HEADER><DETAILS>');

                            END IF;

                            CBS_GAMT := CBS_GAMT + NEFT_CBS_AMT;
                            CBS_GCNT := CBS_GCNT + NEFT_CBS_CNT;
                            UTL_FILE.PUT_LINE(CBS_TXT,'54'
                                                        || BGL
                                                        || LPAD(NEFT_CBS_AMT,14,0)
                                                        || RPAD('00',68) );

                            SL := 0;
                            UTL_FILE.PUT_LINE(CBS_HTML,'<tr><th colspan=10 align=center>Cheque No.'
                                                         || X.CHQ
                                                         || '; Summary Sheet No:'
                                                         || X.SUMMARY_SHEET_NO
                                                         || '; EPFO Bank A/c.No:'
                                                         || AC
                                                         || '; Count:'
                                                         || NEFT_CBS_CNT
                                                         || '; Amount:'
                                                         || REPLACE(TO_CHAR(NEFT_CBS_AMT,FMT),' ')
                                                         || '</th></tr>');

                            FOR Z IN (
                                SELECT
                                    NP.BENEFICIARY_ACCT_NO,
                                    NP.TRAN_AMOUNT,
                                    NP.BENEFICIARY_NAME,
                                    NP.RECIEVER_BANK_IFSC_CODE,
                                    NP.CLAIM_ID,
                                    NP.SCROLL_NO,
                                    NP.DETAILS_OF_PAYMENT,
                                    NP.PAYMENT_ITEM_NO,
                                    ( PCD.PARA_CODE
                                      || ':'
                                      || PCD.SUB_PARA ) AS CTYPE
                                FROM
                                    NEFT_PAYMENT NP
                                    LEFT JOIN PAYMENT_CLAIM_DETAILS PCD ON PCD.CLAIM_ID = NP.CLAIM_ID
                                WHERE
                                    NP.SUMMARY_SHEET_NO = X.SUMMARY_SHEET_NO
                                    AND NP.RECIEVER_BANK_IFSC_CODE LIKE '%SBIN%'
                                    AND NP.SLIP_TYPE = '600'
                                    AND NP.RECORD_STATUS = 0
                                    AND NP.CHEQUE_NO = X.CHQ
                                ORDER BY
                                    NP.SCROLL_NO,
                                    NP.PAYMENT_ITEM_NO
                            ) LOOP
                                UTL_FILE.PUT_LINE(CBS_TXT,'01'
                                                            || LPAD(Z.BENEFICIARY_ACCT_NO,17,0)
                                                            || LPAD(Z.TRAN_AMOUNT,14,0)
                                                            || '00'
                                                            || RPAD(Z.BENEFICIARY_NAME,35)
                                                            || RPAD(Z.DETAILS_OF_PAYMENT,31) );

                                SL := SL + 1;
                                REC := LAC
                                       || SEP
                                       || SL
                                       || SEP
                                       || Z.SCROLL_NO
                                       || SEP
                                       || Z.PAYMENT_ITEM_NO
                                       || SEP
                                       || Z.CLAIM_ID
                                       || SEP
                                       || Z.BENEFICIARY_NAME
                                       || SEP
                                       || Z.BENEFICIARY_ACCT_NO
                                       || SEP
                                       || Z.RECIEVER_BANK_IFSC_CODE
                                       || SEP
                                       || REPLACE(TO_CHAR(Z.TRAN_AMOUNT,FMT),' ')
                                       || SEP
                                       || CASE
                                    WHEN Z.CTYPE != ':' THEN Z.CTYPE
                                    ELSE ''
                                END;

                                UTL_FILE.PUT_LINE(CBS_HTML,CSV2HTML(REC,'N',SEP) );
                                UTL_FILE.PUT_LINE(CBS_XML,'<DET_FLAG>01</DET_FLAG><BEN_AC>'
                                                            || LPAD(Z.BENEFICIARY_ACCT_NO,17,0)
                                                            || '</BEN_AC><AMOUNT>'
                                                            || LPAD(Z.TRAN_AMOUNT,14,0)
                                                            || '00</AMOUNT><BEN_NAME>'
                                                            || RPAD(Z.BENEFICIARY_NAME,35)
                                                            || '</BEN_NAME><PMNT_DETL>'
                                                            || RPAD(Z.DETAILS_OF_PAYMENT,20)
                                                            || '</PMNT_DETL><FROM_AC>'
                                                            || LPAD(AC,11,0)
                                                            || '</FROM_AC>');

                            END LOOP;

                            UTL_FILE.FCLOSE(CBS_TXT);
                        END IF;

                        SELECT
                            SUM(TRAN_AMOUNT),
                            COUNT(BENEFICIARY_ACCT_NO)
                        INTO
                            NEFT_CBS_AMT,
                            NEFT_CBS_CNT
                        FROM
                            NEFT_PAYMENT
                        WHERE
                            SUMMARY_SHEET_NO = X.SUMMARY_SHEET_NO
                            AND RECIEVER_BANK_IFSC_CODE NOT LIKE '%SBIN%'
                            AND SLIP_TYPE = '600'
                            AND RECORD_STATUS = 0
                            AND CHEQUE_NO = X.CHQ;

                        IF NEFT_CBS_AMT > 0 AND NEFT_CBS_CNT > 0 THEN
                            REC := 'NEFT_'
                                   || OFC
                                   || '_'
                                   || ONAME
                                   || '_'
                                   || BCODE
                                   || '_'
                                   || TO_CHAR(TDT,'yyyy-mm-dd');

                            CBS_TXT := UTL_FILE.FOPEN('CCPAP_DIR',REC
                                                                    || '.'
                                                                    || LAC,'W',32767);

                            IF NEFT_GAMT = 0 AND NEFT_GCNT = 0 THEN
                                FNAME := FNAME
                                         || '@'
                                         || CCDIR
                                         || REC
                                         || '#dat,html,01,10';
                                NEFT_HTML := UTL_FILE.FOPEN('CCPAP_DIR',REC || '.html','W',32767);

                                UTL_FILE.PUT_LINE(NEFT_HTML,'<!DOCTYPE html><html><head><title>NEFT PAYMENTS</title>');
                                UTL_FILE.PUT_LINE(NEFT_HTML,'<meta http-equiv="cache-control" content="max-age=0" /><meta http-equiv="cache-control" content="no-cache" /><meta http-equiv="expires" content="0" /><meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" /><meta http-equiv="pragma" content="no-cache" />'
                                );
                                UTL_FILE.PUT_LINE(NEFT_HTML,'</head><body><table border=1><thead><b><center>LIST OF NEFT PAYMENT MADE TO CLAIMANTS HAVING ACCOUNT WITH BANKS OTHER THAN SBI<br>DISPATCH DATE:'
                                                              || UPPER(FROMDATE)
                                                              || '</br></center></b></thead>');
                                UTL_FILE.PUT_LINE(NEFT_HTML,CSV2HTML('A/c.'
                                                                         || SEP
                                                                         || 'Sl'
                                                                         || SEP
                                                                         || 'Scroll'
                                                                         || SEP
                                                                         || 'PID'
                                                                         || SEP
                                                                         || 'Claim id'
                                                                         || SEP
                                                                         || 'Name of the Claimant'
                                                                         || SEP
                                                                         || 'Bank A/c No.'
                                                                         || SEP
                                                                         || 'IFSC Code'
                                                                         || SEP
                                                                         || 'Amount'
                                                                         || SEP
                                                                         || 'Para','Y',SEP) );

                                NEFT_XML := UTL_FILE.FOPEN('CCPAP_DIR',REC || '.dat','W',32767);

                                UTL_FILE.PUT_LINE(NEFT_XML,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><DATA><NEFT_DATA>'

                                );
                            END IF;

                            NEFT_GAMT := NEFT_GAMT + NEFT_CBS_AMT;
                            NEFT_GCNT := NEFT_GCNT + NEFT_CBS_CNT;
                            SL := 0;
                            UTL_FILE.PUT_LINE(NEFT_HTML,'<tr><th colspan=10 align=center>Cheque No.'
                                                          || X.CHQ
                                                          || '; Summary Sheet No:'
                                                          || X.SUMMARY_SHEET_NO
                                                          || '; EPF Bank A/c.No:'
                                                          || AC
                                                          || '; Count:'
                                                          || NEFT_CBS_CNT
                                                          || '; Amount:'
                                                          || REPLACE(TO_CHAR(NEFT_CBS_AMT,FMT),' ')
                                                          || '</th></tr>');

                            FOR Z IN (
                                SELECT
                                    NP.*,
                                    ( PCD.PARA_CODE
                                      || ':'
                                      || PCD.SUB_PARA ) AS CTYPE
                                FROM
                                    NEFT_PAYMENT NP
                                    LEFT JOIN PAYMENT_CLAIM_DETAILS PCD ON PCD.CLAIM_ID = NP.CLAIM_ID
                                WHERE
                                    NP.SUMMARY_SHEET_NO = X.SUMMARY_SHEET_NO
                                    AND NP.RECIEVER_BANK_IFSC_CODE NOT LIKE '%SBIN%'
                                    AND NP.SLIP_TYPE = '600'
                                    AND NP.RECORD_STATUS = 0
                                    AND NP.CHEQUE_NO = X.CHQ
                                ORDER BY
                                    NP.SCROLL_NO,
                                    NP.PAYMENT_ITEM_NO
                            ) LOOP
                                UTL_FILE.PUT_LINE(CBS_TXT,Z.MESSAGE_TYPE
                                                            || LPAD(Z.TRAN_AMOUNT,14,0)
                                                            || '000'
                                                            || LPAD(Z.COMMISSION_AMOUNT,14,0)
                                                            || '000'
                                                            || LPAD(AC,17,0)
                                                            || RPAD(Z.REMITTERS_NAME,35)
                                                            || RPAD(Z.REMITTERS_ADDRESS,35)
                                                            || RPAD(Z.BENEFICIARY_ACCT_NO,32)
                                                            || RPAD(Z.BENEFICIARY_NAME,35)
                                                            || RPAD(Z.BENEFICIARY_ADDRESS,35)
                                                            || RPAD(Z.RECIEVER_BANK_IFSC_CODE,11)
                                                            || RPAD(Z.DETAILS_OF_PAYMENT,35)
                                                            || RPAD(Z.SENDER_TO_RECEIVER_CODE,8)
                                                            || RPAD('RS'
                                                                      || LPAD(Z.TRAN_AMOUNT,11,0)
                                                                      || '00',59)
                                                            || RPAD(SUBSTR(Z.USER_REF_NO,3,15),15)
                                                            || RPAD(EID,35) );

                                SL := SL + 1;
                                REC := LAC
                                       || SEP
                                       || SL
                                       || SEP
                                       || Z.SCROLL_NO
                                       || SEP
                                       || Z.PAYMENT_ITEM_NO
                                       || SEP
                                       || Z.CLAIM_ID
                                       || SEP
                                       || Z.BENEFICIARY_NAME
                                       || SEP
                                       || Z.BENEFICIARY_ACCT_NO
                                       || SEP
                                       || Z.RECIEVER_BANK_IFSC_CODE
                                       || SEP
                                       || REPLACE(TO_CHAR(Z.TRAN_AMOUNT,FMT),' ')
                                       || SEP
                                       || CASE
                                    WHEN Z.CTYPE != ':' THEN Z.CTYPE
                                    ELSE ''
                                END;

                                UTL_FILE.PUT_LINE(NEFT_HTML,CSV2HTML(REC,'N',SEP) );
                                UTL_FILE.PUT_LINE(NEFT_XML,'<MESG>'
                                                             || Z.MESSAGE_TYPE
                                                             || '</MESG><TRAN_AMT>'
                                                             || LPAD(Z.TRAN_AMOUNT,14,0)
                                                             || '000</TRAN_AMT><COMM_AMT>'
                                                             || LPAD(Z.COMMISSION_AMOUNT,14,0)
                                                             || '000</COMM_AMT><FROM_ACNO>'
                                                             || LPAD(AC,17,0)
                                                             || '</FROM_ACNO><FROM_NAME>'
                                                             || RPAD(Z.REMITTERS_NAME,35)
                                                             || '</FROM_NAME><FROM_ADDR>'
                                                             || RPAD(Z.REMITTERS_ADDRESS,35)
                                                             || '</FROM_ADDR><BEN_ACNO>'
                                                             || RPAD(Z.BENEFICIARY_ACCT_NO,32)
                                                             || '</BEN_ACNO><BEN_NAME>'
                                                             || RPAD(Z.BENEFICIARY_NAME,35)
                                                             || '</BEN_NAME><BEN_ADDR>'
                                                             || RPAD(Z.BENEFICIARY_ADDRESS,35)
                                                             || '</BEN_ADDR><BEN_IFSC>'
                                                             || RPAD(Z.RECIEVER_BANK_IFSC_CODE,11)
                                                             || '</BEN_IFSC><DETL_PMNT>'
                                                             || RPAD(Z.DETAILS_OF_PAYMENT,35)
                                                             || '</DETL_PMNT><SEND_RECV>'
                                                             || RPAD(Z.SENDER_TO_RECEIVER_CODE,8)
                                                             || '</SEND_RECV><MISC_ENTRY>'
                                                             || RPAD('RS'
                                                                       || LPAD(Z.TRAN_AMOUNT,11,0)
                                                                       || '00',59)
                                                             || '</MISC_ENTRY><USER_REF>'
                                                             || RPAD(SUBSTR(Z.USER_REF_NO,3,15),15)
                                                             || '</USER_REF><EMAIL>'
                                                             || RPAD(EID,35)
                                                             || '</EMAIL>');

                            END LOOP;

                            UTL_FILE.FCLOSE(CBS_TXT);
                        END IF;

                    END IF;

                END IF;

            END LOOP;

            IF TOTAMT > 0 THEN
                REC := SEP
                       || LAC
                       || SEP
                       || 'A/c.Total:'
                       || SEP
                       || TOT
                       || SEP
                       || REPLACE(TO_CHAR(TOTAMT,FMT),' ')
                       || SEP
                       || SEP
                       || SEP
                       || SEP
                       || SEP;

                UTL_FILE.PUT_LINE(FP,REC);
                UTL_FILE.PUT_LINE(HTML,CSV2HTML(REC,'Y',SEP) );
            END IF;

        END LOOP;

        UTL_FILE.PUT_LINE(XML,'  </DETAILS>');
        UTL_FILE.PUT_LINE(XML,' </DATA>');
        UTL_FILE.PUT_LINE(XML,'</CCPAP_DATA>');
        REC := SEP
               || SEP
               || 'Grand Total:'
               || SEP
               || GTOT
               || SEP
               || REPLACE(TO_CHAR(GTOTAMT,FMT),' ')
               || SEP
               || SEP
               || SEP
               || SEP;

        UTL_FILE.PUT_LINE(FP,REC);
        UTL_FILE.PUT_LINE(HTML,CSV2HTML(REC,'Y',SEP)
                                 || '</table>'
                                 ||
            CASE
                WHEN BLANK_CNT > 0 THEN BLANK_CNT || ' records found with blank payee name (#)'
            END
                                 || '</body></html>');

        UTL_FILE.FCLOSE(FP);
        UTL_FILE.FCLOSE(XML);
        UTL_FILE.FCLOSE(HTML);
        FILENAME := FNAME;
        IF ( CBS_GAMT > 0 AND CBS_GCNT > 0 ) THEN
            UTL_FILE.PUT_LINE(CBS_HTML,'<tr><th colspan=10 align=left>Total CBS Records Dispatched on '
                                         || UPPER(FROMDATE)
                                         || ': '
                                         || CBS_GCNT
                                         || ';  Total CBS Amount:'
                                         || REPLACE(TO_CHAR(CBS_GAMT,FMT),' ')
                                         || '</th></tr></table></body></html>');

            UTL_FILE.PUT_LINE(CBS_XML,'</DETAILS></CBS_DATA></DATA>');
            UTL_FILE.FCLOSE(CBS_HTML);
            UTL_FILE.FCLOSE(CBS_XML);
        END IF;

        IF ( NEFT_GAMT > 0 AND NEFT_GCNT > 0 ) THEN
            UTL_FILE.PUT_LINE(NEFT_HTML,'<tr><th colspan=10 align=left>Total NEFT Records Dispatched on '
                                          || UPPER(FROMDATE)
                                          || ': '
                                          || NEFT_GCNT
                                          || ';  Total NEFT Amount:'
                                          || REPLACE(TO_CHAR(NEFT_GAMT,FMT),' ')
                                          || '</th></tr></table></body></html>');

            UTL_FILE.PUT_LINE(NEFT_XML,'</NEFT_DATA></DATA>');
            UTL_FILE.FCLOSE(NEFT_HTML);
            UTL_FILE.FCLOSE(NEFT_XML);
        END IF;

    END IF;

    KEY := 'g3V0k0yqHDVIj74npajDrZgPHJMskcDxwHdpy96bIrp8Y64MVUrHO';
END GENERATE_CCPAP_FILE;

/
