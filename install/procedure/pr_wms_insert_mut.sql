CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_insert_mut`(
     IN p_org_id            INT
    ,IN p_txn_id            INT
    ,IN p_serial_number     VARCHAR(30)
	,IN p_item_id           INT  
    ,IN p_subinv_code       VARCHAR(10) 
    ,IN p_locator_id        INT
    ,IN p_user_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_insert_mut
-- Description    : Insert Unit Transaction
-- 2016/03/06 ksoocho 최초 작성
-- **********************************************

DECLARE v_txn_type_id         INT;  
DECLARE v_txn_source_type_id  INT; 
DECLARE v_txn_qty             INT; 
DECLARE v_receipt_issue_type  INT;
DECLARE v_xfer_lpn_id         INT;
DECLARE v_lpn_id              INT;
DECLARE v_con_lpn_id          INT;

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_check_count  INT DEFAULT 0; 
DECLARE v_return_value INT DEFAULT 0;   

DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
BEGIN
	GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	 @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	SELECT @full_error;

    SET x_returnCode = 'E';
    SET x_returnMsg =  CONCAT('Error-',v_process,'-',@full_error);
    
    ROLLBACK;
END;

-- Common Code check
SET v_returnCode = 'S';
SET v_returnMsg = 'Success!!'; 

SET v_process = '1000';

IF ( p_org_id IS NULL )
   OR ( p_txn_id IS NULL ) 
   OR ( p_serial_number IS NULL ) 
   OR ( p_item_id IS NULL ) 
   THEN
       
	SET v_returnCode = 'E';
	SET v_returnMsg = 'Input Parameter'; 

END IF;  

-- Check - Organization Item
IF v_returnCode = 'S' THEN

    SET v_process = '1002';

    SELECT f_wms_check_item_serial(
            p_org_id
           ,p_item_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Item-Serial'; 
    END IF;

END IF;

-- --------------------------
-- Transaction ID
-- --------------------------
IF v_returnCode = 'S' THEN

    SET v_process = '1003';

	SELECT TRANSACTION_TYPE_ID
          ,TRANSACTION_QUANTITY 
          ,TRANSFER_LPN_ID
          ,LPN_ID
          ,CONTENT_LPN_ID
	INTO v_txn_type_id
        ,v_txn_qty 
        ,v_xfer_lpn_id
        ,v_lpn_id
        ,v_con_lpn_id
	FROM  cks_wms_mmt mmt
	WHERE mmt.TRANSACTION_ID  = p_txn_id;
    
    IF v_txn_type_id IS NULL THEN
       SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Transaction ID'; 
    END IF;

END IF;

-- --------------------------
-- Transaction Type ID
-- --------------------------
IF v_returnCode = 'S' THEN

    SET v_process = '1004';

	SELECT TRANSACTION_SOURCE_TYPE_ID
	INTO v_txn_source_type_id
	FROM  cks_wms_mtt mtt
	WHERE mtt.TRANSACTION_TYPE_ID = v_txn_type_id;
    
    IF v_txn_source_type_id IS NULL THEN
       SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Transaction Type ID'; 
    END IF;

END IF;

IF v_txn_qty  < 0 THEN
   SET v_receipt_issue_type  = 1 ;
ELSE
   SET v_receipt_issue_type  = 2 ;
END IF;

-- ---------------------------------------
-- Insert Material Unit Transaction
-- ---------------------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '2000';

	INSERT INTO cks_wms_mut
	(TRANSACTION_ID
	,SERIAL_NUMBER 
	,INVENTORY_ITEM_ID
	,ORGANIZATION_ID  
	,SUBINVENTORY_CODE
	,LOCATOR_ID   
	,TRANSACTION_DATE 
	,TRANSACTION_SOURCE_TYPE_ID
	,TRANSACTION_SOURCE_ID  
	,TRANSACTION_SOURCE_NAME
	,RECEIPT_ISSUE_TYPE 
	,CREATION_DATE  
	,CREATED_BY       
	,LAST_UPDATE_DATE 
	,LAST_UPDATED_BY  
	) VALUES 
	(p_txn_id
     ,p_serial_number
	 ,p_item_id
     ,p_org_id
     ,p_subinv_code
     ,p_locator_id
     ,SYSDATE() -- txn_date
     ,v_txn_source_type_id
     ,NULL
     ,NULL
     ,v_receipt_issue_type 
	 ,SYSDATE()
	 ,p_user_id
	 ,SYSDATE()
	 ,p_user_id
	);

END IF;

-- ---------------------------------------
-- Receipt (18, 42, 44, 37)
-- ---------------------------------------
IF v_txn_type_id IN (18, 42, 44, 37) THEN

   UPDATE cks_wms_msn msn
       SET CURRENT_STATUS  = 3
          ,CURRENT_SUBINVENTORY_CODE = p_subinv_code
          ,CURRENT_LOCATOR_ID = p_locator_id
          ,LAST_UPDATE_DATE = SYSDATE()
	      ,LAST_UPDATED_BY = p_user_id 
   WHERE  INVENTORY_ITEM_ID =  p_item_id
   AND     SERIAL_NUMBER = p_serial_number;
   
END IF;

-- ---------------------------------------
-- Issue (32, 33, 35, 36)
-- ---------------------------------------
IF v_txn_type_id IN (32, 33, 35, 36) THEN

   UPDATE cks_wms_msn msn
       SET CURRENT_STATUS  = 4
          ,LAST_UPDATE_DATE = SYSDATE()
	      ,LAST_UPDATED_BY = p_user_id 
   WHERE  INVENTORY_ITEM_ID =  p_item_id
   AND     SERIAL_NUMBER = p_serial_number;
   
END IF;

-- ---------------------------------------
-- Pack Transaction (87)
-- ---------------------------------------
IF v_txn_type_id = 87 THEN

   UPDATE cks_wms_msn msn
       SET LPN_ID = v_xfer_lpn_id
          ,CURRENT_STATUS  = (IF (CURRENT_STATUS = 4, 3, CURRENT_STATUS ) )
          ,CURRENT_SUBINVENTORY_CODE = p_subinv_code
          ,CURRENT_LOCATOR_ID = p_locator_id
          ,LAST_UPDATE_DATE = SYSDATE()
	      ,LAST_UPDATED_BY = p_user_id 
   WHERE  INVENTORY_ITEM_ID =  p_item_id
   AND     SERIAL_NUMBER = p_serial_number;
   
END IF;

-- ---------------------------------------
-- UnPack Transaction (88)
-- ---------------------------------------
IF v_txn_type_id = 88 THEN

   UPDATE cks_wms_msn msn
       SET LPN_ID = NULL
          ,LAST_UPDATE_DATE = SYSDATE()
	      ,LAST_UPDATED_BY = p_user_id 
   WHERE  INVENTORY_ITEM_ID =  p_item_id
   AND     SERIAL_NUMBER = p_serial_number;
   
END IF;

-- ---------------------------------------
-- Split Transaction (89)
-- ---------------------------------------
IF v_txn_type_id = 89 THEN

   UPDATE cks_wms_msn msn
       SET LPN_ID = v_xfer_lpn_id
          ,LAST_UPDATE_DATE = SYSDATE()
	      ,LAST_UPDATED_BY = p_user_id 
   WHERE  INVENTORY_ITEM_ID =  p_item_id
   AND     SERIAL_NUMBER = p_serial_number;
   
END IF;

-- ---------------------------------------
-- Subinventory Transfer (2)
-- ---------------------------------------
IF v_txn_type_id = 2 
   AND v_receipt_issue_type  = 1 THEN

   UPDATE cks_wms_msn msn
       SET CURRENT_SUBINVENTORY_CODE = p_subinv_code
          ,CURRENT_LOCATOR_ID = p_locator_id
          ,LAST_UPDATE_DATE = SYSDATE()
	      ,LAST_UPDATED_BY = p_user_id 
   WHERE  INVENTORY_ITEM_ID =  p_item_id
   AND     SERIAL_NUMBER = p_serial_number;
   
END IF;

-- ---------------------------------------
-- Direct Organization Transfer (3)
-- ---------------------------------------
IF v_txn_type_id = 3 
   AND v_receipt_issue_type  = 1 THEN

   UPDATE cks_wms_msn msn
       SET CURRENT_ORGANIZATION_ID = p_org_id
          ,CURRENT_SUBINVENTORY_CODE = p_subinv_code
          ,CURRENT_LOCATOR_ID = p_locator_id
          ,LAST_UPDATE_DATE = SYSDATE()
	      ,LAST_UPDATED_BY = p_user_id 
   WHERE  INVENTORY_ITEM_ID =  p_item_id
   AND     SERIAL_NUMBER = p_serial_number;
   
END IF;


IF v_returnCode = 'S' THEN
    SET x_returnCode = 'S';
	SET x_returnMsg = v_returnMsg; 
ELSE
    SET x_returnCode = 'E';
	SET x_returnMsg = CONCAT('Error-',v_process,'-',v_returnMsg);
    ROLLBACK;
END IF;

END