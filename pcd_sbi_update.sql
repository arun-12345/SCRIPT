--------------------------------------------------------
--  File created - Wednesday-February-13-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure PCD_SBI_UPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "PCD_SBI_UPDATE" (
    UPLOADID IN VARCHAR2,
    STATUS OUT NOCOPY VARCHAR2 )
AS
BEGIN
  DECLARE
    VCLAIMID     VARCHAR2(17):=NULL;
    UPD_PCD_FLAG VARCHAR2(1);
    UPD_UTR_FLAG VARCHAR2(1);
    COUNTER      NUMBER(12)  :=0;
    ROWIDVAR     VARCHAR2(30):=0;
    CURSOR C1
    IS
      SELECT UTR_REF_NO,
        ACCOUNT_NO,
        AMOUNT,
        SBI_OTHER_FLAG,
        CREDIT_DATE
      FROM NEFT_TRANSACTION_UPLOAD_SBI
      WHERE UPLOAD_ID  =UPLOADID
      AND SLIP_TYPE    =300
      AND RECORD_STATUS=0
      ORDER BY UTR_REF_NO;
  BEGIN


    FOR X IN C1
    LOOP

      SELECT COUNT(1)
      INTO COUNTER
      FROM PAYMENT_CLAIM_DETAILS
      WHERE PAYMENT_MODE ='N'
      AND TOTAL_AMOUNT   =X.AMOUNT
      AND UTR_REF_NO    IS NULL
      AND IFSC_CODE LIKE 'SBIN%'
      AND RMO_CODE                     IS NULL
      AND RMO_STATUS                   IS NULL
      AND DISPATCH_CODE                IS NOT NULL
      AND DISPATCH_NO                  IS NOT NULL
      AND DISPATCH_DATE                IS NOT NULL
      AND TO_CHAR(TO_NUMBER(ACCOUNT_NO))=TO_CHAR(TO_NUMBER(X.ACCOUNT_NO));
      DBMS_OUTPUT.PUT_LINE('counter  '||COUNTER);
      DBMS_OUTPUT.PUT_LINE('vCLAIMID  '||X.UTR_REF_NO);
      IF(COUNTER=0) THEN

        UPDATE NEFT_TRANSACTION_UPLOAD_SBI
        SET SLIP_TYPE   ='600',
          PCD_MIS_DOUBLE='M'
        WHERE UPLOAD_ID =UPLOADID
        AND UTR_REF_NO  =X.UTR_REF_NO;
        STATUS         :=' ';
        COMMIT;
      ELSE
        IF(COUNTER=1) THEN

          UPDATE PAYMENT_CLAIM_DETAILS
          SET UTR_REF_NO     =X.UTR_REF_NO
          WHERE PAYMENT_MODE ='N'
          AND TOTAL_AMOUNT   =X.AMOUNT
          AND UTR_REF_NO    IS NULL
          AND IFSC_CODE LIKE 'SBIN%'
          AND RMO_CODE                     IS NULL
          AND RMO_STATUS                   IS NULL
          AND DISPATCH_CODE                IS NOT NULL
          AND DISPATCH_NO                  IS NOT NULL
          AND DISPATCH_DATE                IS NOT NULL
          AND TO_CHAR(TO_NUMBER(ACCOUNT_NO))=TO_CHAR(TO_NUMBER(X.ACCOUNT_NO));
          IF (SQL%FOUND) THEN
            UPD_PCD_FLAG:=1;
          ELSE
            UPD_PCD_FLAG:=0;
          END IF;

          UPDATE NEFT_TRANSACTION_UPLOAD_SBI
          SET SLIP_TYPE   ='600',
            PCD_MIS_DOUBLE='C'
          WHERE UPLOAD_ID =UPLOADID
          AND UTR_REF_NO  =X.UTR_REF_NO;

          IF (SQL%FOUND) THEN
            UPD_UTR_FLAG:=1;
          ELSE
            UPD_UTR_FLAG:=0;
          END IF;
          IF (UPD_PCD_FLAG=1 AND UPD_UTR_FLAG=1) THEN
            STATUS       :='PCD UPDATED';
            COMMIT;
          ELSE
            STATUS:='  ';
            ROLLBACK;
          END IF;
        ELSE
          IF(COUNTER>1) THEN

            SELECT COUNT(1)
            INTO ROWIDVAR
            FROM PAYMENT_CLAIM_DETAILS
            WHERE PAYMENT_MODE ='N'
            AND TOTAL_AMOUNT   =X.AMOUNT
            AND UTR_REF_NO    IS NULL
            AND IFSC_CODE LIKE 'SBIN%'
            AND RMO_CODE                     IS NULL
            AND RMO_STATUS                   IS NULL
            AND DISPATCH_CODE                IS NOT NULL
            AND DISPATCH_NO                  IS NOT NULL
            AND DISPATCH_DATE                IS NOT NULL
            AND TO_CHAR(TO_NUMBER(ACCOUNT_NO))=TO_CHAR(TO_NUMBER(X.ACCOUNT_NO));


            IF ROWIDVAR = 1 THEN
              SELECT ROWID
              INTO ROWIDVAR
              FROM PAYMENT_CLAIM_DETAILS
              WHERE PAYMENT_MODE ='N'
              AND TOTAL_AMOUNT   =X.AMOUNT
              AND UTR_REF_NO    IS NULL
              AND IFSC_CODE LIKE 'SBIN%'
              AND RMO_CODE                     IS NULL
              AND RMO_STATUS                   IS NULL
              AND DISPATCH_CODE                IS NOT NULL
              AND DISPATCH_NO                  IS NOT NULL
              AND DISPATCH_DATE                IS NOT NULL
              AND TO_CHAR(TO_NUMBER(ACCOUNT_NO))=TO_CHAR(TO_NUMBER(X.ACCOUNT_NO));
            ELSE
              IF ROWIDVAR > 1 THEN
                SELECT ROWID
                INTO ROWIDVAR
                FROM PAYMENT_CLAIM_DETAILS
                WHERE PAYMENT_MODE ='N'
                AND TOTAL_AMOUNT   =X.AMOUNT
                AND UTR_REF_NO    IS NULL
                AND IFSC_CODE LIKE 'SBIN%'
                AND RMO_CODE                     IS NULL
                AND RMO_STATUS                   IS NULL
                AND DISPATCH_CODE                IS NOT NULL
                AND DISPATCH_NO                  IS NOT NULL
                AND DISPATCH_DATE                IS NOT NULL
                AND TO_CHAR(TO_NUMBER(ACCOUNT_NO))=TO_CHAR(TO_NUMBER(X.ACCOUNT_NO))
                AND ROWNUM                        = 1;
              END IF;
            END IF;



            UPDATE PAYMENT_CLAIM_DETAILS
            SET UTR_REF_NO     =X.UTR_REF_NO,
              CERTIFIED_REMARKS='DOUBLE RECORDS AGAINST SAME MEMBER ACCOUNT '
              ||X.ACCOUNT_NO
              ||' AND TOTAL AMOUNT'
              ||X.AMOUNT
            WHERE PAYMENT_MODE ='N'
            AND TOTAL_AMOUNT   =X.AMOUNT
            AND UTR_REF_NO    IS NULL
            AND IFSC_CODE LIKE 'SBIN%'
            AND RMO_CODE                     IS NULL
            AND RMO_STATUS                   IS NULL
            AND DISPATCH_CODE                IS NOT NULL
            AND DISPATCH_NO                  IS NOT NULL
            AND DISPATCH_DATE                IS NOT NULL
            AND TO_CHAR(TO_NUMBER(ACCOUNT_NO))=TO_CHAR(TO_NUMBER(X.ACCOUNT_NO))
            AND ROWID                         =ROWIDVAR;
            IF (SQL%FOUND) THEN
              UPD_PCD_FLAG:=1;
            ELSE
              UPD_PCD_FLAG:=0;
            END IF;
            DBMS_OUTPUT.PUT_LINE('vCLAIMID  '||X.UTR_REF_NO);
            UPDATE NEFT_TRANSACTION_UPLOAD_SBI
            SET SLIP_TYPE   ='600',
              PCD_MIS_DOUBLE='D'
            WHERE UPLOAD_ID =UPLOADID
            AND UTR_REF_NO  =X.UTR_REF_NO;
            IF (SQL%FOUND) THEN
              UPD_UTR_FLAG:=1;
            ELSE
              UPD_UTR_FLAG:=0;
            END IF;
            IF (UPD_PCD_FLAG=1 AND UPD_UTR_FLAG=1) THEN
              STATUS       :='PCD UPDATED';
              COMMIT;
            ELSE
              STATUS:=' ';
              ROLLBACK;
            END IF;
          END IF;
        END IF;
      END IF;
      COUNTER:=-1;
    END LOOP;

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE ( 'No Record Found ' ) ;
    STATUS:=SQLERRM;
    ROLLBACK;
  WHEN OTHERS THEN
    BEGIN
      DBMS_OUTPUT.PUT_LINE ( 'Exception in '||SQLERRM ) ;
      STATUS:=SQLERRM;
      ROLLBACK;
    END;
  END;
END PCD_SBI_UPDATE;

/
