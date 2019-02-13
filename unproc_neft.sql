--------------------------------------------------------
--  File created - Wednesday-February-13-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure UNPROC_NEFT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "UNPROC_NEFT" 
  (
    SLIPTYPE  IN VARCHAR2,
    CREATEDBY IN VARCHAR2,
    CREATEDON IN VARCHAR2,
    UPLOADID  IN VARCHAR2,
    STATUS OUT NOCOPY NUMBER)
IS
BEGIN
  DECLARE
    COUNTER             NUMBER(12)  :=0;
    UTR_FLAG            VARCHAR2(12):=0;
    UPL_UTR_FLAG        VARCHAR2(12):=0;
    OFFTYPE_UTR_ET_FLAG NUMBER(12)   :=0;
    OFFTYPE_UTR_ET_CNT  NUMBER(12)   :=0;
    SUMMARYSHEETNO      VARCHAR2(30):='';
    OFFICETYPE          VARCHAR2(5) :='';

    CURSOR C
    IS
      SELECT DISTINCT SUMMARY_SHEET_NO
         FROM PAYMENT_CLAIM_DETAILS PCD,
        NEFT_TRANSACTION_UTR_UPLOAD_ET NTU
        WHERE SUBSTR(PCD.CLAIM_ID,3,17) = NTU.USER_REF_NO
      AND PCD.IFSC_CODE NOT LIKE '%SBIN%'
      AND PCD.DISPATCH_NO               <>'9999999999'
      AND PCD.RMO_CODE                  IS NULL
      AND PCD.RECON_NEFT_PAYMENT_UPLOAD IS NULL
      AND PCD.PAYMENT_MODE               ='N'
      AND PCD.DISPATCH_NO               IS NOT NULL
      AND PCD.CHEQUE_NO                 <>'9999999999'
      AND PCD.RMO_STATUS                IS NULL;
  BEGIN
    FOR X IN C
    LOOP
      SUMMARYSHEETNO:='';
      SUMMARYSHEETNO:=X.SUMMARY_SHEET_NO;

      DECLARE
        CURSOR C1
        IS
           SELECT CLAIM_ID,
            IFSC_CODE     ,
            TOTAL_AMOUNT  ,
            ACCOUNT_NO
             FROM PAYMENT_CLAIM_DETAILS PCD
            WHERE SUBSTR(PCD.CLAIM_ID,3,17) NOT IN
            (SELECT USER_REF_NO FROM NEFT_TRANSACTION_UTR_UPLOAD_ET
            )
        AND PCD.SUMMARY_SHEET_NO=SUMMARYSHEETNO
        AND PCD.PAYMENT_MODE    ='N'
        AND PCD.IFSC_CODE NOT LIKE '%SBIN%'
        AND PCD.DISPATCH_NO               <>'9999999999'
        AND PCD.UTR_REF_NO                IS NULL
        AND PCD.RMO_CODE                  IS NULL
        AND PCD.RECON_NEFT_PAYMENT_UPLOAD IS NULL
        AND PCD.CHEQUE_NO                 <>'9999999999'
        AND PCD.RMO_STATUS                IS NULL;
      BEGIN
        FOR Y IN C1
        LOOP

           INSERT
             INTO NEFT_TRANSACTION_UPLOAD
            (
              UTR_REF_NO     ,
              AMOUNT         ,
              RECEIVED_BRANCH,
              STATUS         ,
              UPLOAD_ID      ,
              SLIP_TYPE      ,
              RECORD_STATUS  ,
              CREATED_BY     ,
              CREATED_DATE   ,
              CREATED_ON
            )
            VALUES
            (
              Y.CLAIM_ID               ,
              Y.TOTAL_AMOUNT           ,
              Y.IFSC_CODE              ,
              'UNPROCESSED TRANSACTION',
              UPLOADID                 ,
              '600'                    ,
              0                        ,
              CREATEDBY                ,
              SYSDATE                  ,
              CREATEDON
            );
          IF
            (
              SQL%FOUND
            )
            THEN
            UPL_UTR_FLAG:=UPL_UTR_FLAG+1;
          ELSE
            UPL_UTR_FLAG:=0;
          END IF;

           INSERT
             INTO NEFT_TRANSACTION_UTR_UPLOAD
            (
              UTR_REF_NO     ,
              ACCOUNT_NO     ,
              AMOUNT         ,
              RECEIVED_BRANCH,
              STATUS         ,
              ERROR_DESC     ,
              UPLOAD_ID      ,
              SLIP_TYPE      ,
              RECORD_STATUS  ,
              CREATED_BY     ,
              CREATED_DATE   ,
              CREATED_ON     ,
              MSG_TYPE       ,
              USER_REF_NO
            )
            VALUES
            (
              Y.CLAIM_ID               ,
              Y.ACCOUNT_NO             ,
              Y.TOTAL_AMOUNT           ,
              Y.IFSC_CODE              ,
              'UNPROC'                 ,
              'UNPROCESSED TRANSACTION',
              UPLOADID                 ,
              SLIPTYPE                 ,
              0                        ,
              CREATEDBY                ,
              SYSDATE                  ,
              CREATEDON                ,
              'R41'                    ,
              SUBSTR(Y.CLAIM_ID,3,17)
            );
          IF
            (
              SQL%FOUND
            )
            THEN
            UTR_FLAG:=UTR_FLAG+1;
          ELSE
            UTR_FLAG:=0;
          END IF;
          COUNTER:=COUNTER+1;
        END LOOP;
      END;

    END LOOP;



     SELECT REGION_CODE
       INTO OFFICETYPE
       FROM EPFO_OFF_MASTER
      WHERE SLIP_TYPE='600'
    AND RECORD_STATUS=0;

    OFFTYPE_UTR_ET_CNT:=0;
     SELECT COUNT(1)
       INTO OFFTYPE_UTR_ET_CNT
       FROM NEFT_TRANSACTION_UTR_UPLOAD_ET
      WHERE UTR_REF_NO   IS NULL;
    IF(OFFTYPE_UTR_ET_CNT =0) THEN
      OFFTYPE_UTR_ET_FLAG:=1;
    ELSE
       INSERT
         INTO NEFT_TRANSACTION_UPLOAD
        (
          UTR_REF_NO     ,
          AMOUNT         ,
          RECEIVED_BRANCH,
          STATUS         ,
          UPLOAD_ID      ,
          SLIP_TYPE      ,
          RECORD_STATUS  ,
          CREATED_BY     ,
          CREATED_DATE   ,
          CREATED_ON
        )
       SELECT OFFICETYPE
        ||USER_REF_NO   ,
        AMOUNT          ,
        RECEIVED_BRANCH ,
        ERROR_DESC      ,
        UPLOADID        ,
        '600'           ,
        0               ,
        CREATEDBY       ,
        SYSDATE         ,
        CREATEDON
         FROM NEFT_TRANSACTION_UTR_UPLOAD_ET
        WHERE UTR_REF_NO IS NULL ;
      IF ( SQL%FOUND ) THEN
        OFFTYPE_UTR_ET_FLAG:=1;
      ELSE
        OFFTYPE_UTR_ET_FLAG:=0;
      END IF;
    END IF;
    IF ( UTR_FLAG=UPL_UTR_FLAG AND OFFTYPE_UTR_ET_FLAG=1 ) THEN
      STATUS    :=COUNTER;
      COMMIT;
    ELSE

      ROLLBACK;
       DELETE NEFT_TRANSACTION_UTR_UPLOAD WHERE UPLOAD_ID=UPLOADID;
      COMMIT;
    END IF;
  END;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  STATUS :=0;
  DBMS_OUTPUT.PUT_LINE ( 'No Record Found ' ) ;
  ROLLBACK;
   DELETE NEFT_TRANSACTION_UTR_UPLOAD WHERE UPLOAD_ID=UPLOADID;
  COMMIT;
WHEN OTHERS THEN
  STATUS :=0;
  DBMS_OUTPUT.PUT_LINE ( 'Exception in '||SQLERRM ) ;
  ROLLBACK;
   DELETE NEFT_TRANSACTION_UTR_UPLOAD WHERE UPLOAD_ID=UPLOADID;
  COMMIT;
END UNPROC_NEFT;

/
