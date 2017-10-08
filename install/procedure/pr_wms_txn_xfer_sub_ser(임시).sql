CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_txn_xfer_sub_ser`(
     IN p_org_id            INT
    ,IN p_subinv_code       VARCHAR(10) 
    ,IN p_locator_code      VARCHAR(40) 
    ,IN p_xfer_subinv_code  VARCHAR(10) 
    ,IN p_xfer_locator_code VARCHAR(40) 
	,IN p_item_code         VARCHAR(40)  
    ,IN p_serial_no         VARCHAR(30) 
    ,IN p_txn_reference     VARCHAR(240)  
    ,IN p_user_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_txn_subinv_transfer
-- Description    : 재고이동 ( No Serial Control )
-- 2016/03/06 ksoocho 최초 작성
-- **********************************************
DECLARE v_txn_uom           VARCHAR(3);
DECLARE v_locator_id        INT;
DECLARE v_xfer_locator_id   INT;
DECLARE v_item_id           INT;
DECLARE v_txn_type_id       INT;
DECLARE v_issue_txn_id      INT;
DECLARE v_receipt_txn_id    INT;
DECLARE v_onhand_loose_qty  INT; 

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

SET v_txn_uom = 'EA';

-- txn_type_id (2) 
-- Subinventory Transfer 
SET v_txn_type_id = 2;

-- ------------------------------
-- Validation Routine
-- ------------------------------
IF ( p_org_id IS NULL ) 
   OR ( p_subinv_code IS NULL ) 
   OR ( p_locator_code IS NULL ) 
   OR ( p_xfer_subinv_code IS NULL ) 
   OR ( p_xfer_locator_code IS NULL ) 
   OR ( p_item_code IS NULL ) 
   OR ( p_txn_qty IS NULL ) 
   OR ( p_txn_qty <= 0 ) THEN

   SET v_returnCode = 'E';
   SET v_returnMsg = 'Invalid Parameter'; 

END IF;

-- Get Locator ID
IF v_returnCode = 'S' THEN

	SET v_process = '11';

    SELECT f_wms_get_locator_id(
            p_org_id
           ,p_locator_code)
    INTO v_locator_id; 

    IF v_locator_id < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Locator'; 
    END IF;

END IF;

-- Get Locator ID
IF v_returnCode = 'S' THEN

	SET v_process = '11';

    SELECT f_wms_get_locator_id(
            p_xfer_org_id
           ,p_xfer_locator_code)
    INTO v_xfer_locator_id; 

    IF v_xfer_locator_id < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Locator'; 
    END IF;

END IF;

-- Get Item ID
IF v_returnCode = 'S' THEN

	SET v_process = '11';

    SELECT f_wms_get_item_id(
            p_org_id
           ,p_item_code)
    INTO v_item_id; 

    IF v_item_id < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Item'; 
    END IF;

END IF;

-- Check - Subinventory / Locator
IF v_returnCode = 'S' THEN

	SET v_process = '11';

    SELECT f_wms_check_locator(
            p_org_id
           ,p_subinv_code
           ,v_locator_id)
    INTO v_return_value; 

    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Locator'; 
    END IF;

END IF;

-- Check - Transfer Subinventory / Locator
IF v_returnCode = 'S' THEN

	SET v_process = '12';

    SELECT f_wms_check_locator(
            p_org_id
           ,p_xfer_subinv_code
           ,v_xfer_locator_id)
    INTO v_return_value; 

    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Locator'; 
    END IF;

END IF;

-- Check - Organization Item
IF v_returnCode = 'S' THEN

	SET v_process = '13';

    SELECT f_wms_check_item(
            p_org_id
           ,v_item_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Item'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

   SELECT COUNT(*)
   INTO v_check_count
   FROM cks_wms_msn
   WHERE SERIAL_NUMBER = p_serial_no
   AND   CURRENT_ORGANIZATION_ID = p_org_id
   AND   CURRENT_SUBINVENTORY_CODE = p_subinv_code
   AND   CURRENT_LOCATOR_ID = v_locator_id
   AND   INVENTORY_ITEM_ID = v_item_id
   AND   CURRENT_STATUS = 3;   
   
    IF v_check_count = 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Serial'; 
    END IF;

END IF;

-- -------------------------
-- Insert MMT
-- -------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '21';

    START TRANSACTION;

	-- -------------------------
	-- From Locator Transaction
	-- -------------------------
	CALL pr_wms_insert_mmt(
		p_org_id  
	   ,p_subinv_code 
	   ,v_locator_id 
	   ,v_item_id  
	   ,v_txn_type_id
	   ,p_txn_qty * (-1) 
	   ,v_txn_uom  
	   ,p_txn_reference 
	   ,NULL -- p_lpn_id   
	   ,NULL -- p_content_lpn_id
	   ,p_org_id -- p_xfer_org_id  
	   ,p_xfer_subinv_code 
	   ,v_xfer_locator_id
	   ,NULL -- p_xfer_lpn_id
	   ,p_user_id -- p_user_id 
	   ,v_issue_txn_id 
	   ,v_returnCode 
	   ,v_returnMsg
	   );
   
END IF;

-- -------------------------
-- Insert MOQ  ( No LPN )
-- -------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '22';

	CALL pr_wms_process_moq(
		  p_org_id 
		, p_subinv_code
		, v_locator_id 
		, v_item_id
		, NULL -- p_lpn_id 
		, p_txn_qty * (-1) 
		, v_txn_uom  
		, p_user_id
		, v_returnCode
		, v_returnMsg
	);
	
END IF; 

-- -------------------------
-- Insert MOQ
-- -------------------------
IF v_returnCode = 'S' THEN

   SET v_process = '40';

   CALL pr_wms_insert_mut (
	  p_org_id
	, v_issue_txn_id
	, p_serial_no
	, v_item_id
	, p_subinv_code 
	, v_locator_id 
	, p_user_id  
	, v_returnCode 
	, v_returnMsg
   );   

END IF;

-- -------------------------
-- Xfer Locator Transaction
-- -------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '31';

	CALL pr_wms_insert_mmt(
		p_org_id  
	   ,p_xfer_subinv_code 
	   ,v_xfer_locator_id 
	   ,v_item_id  
	   ,v_txn_type_id
	   ,p_txn_qty  
	   ,v_txn_uom  
	   ,p_txn_reference 
	   ,NULL -- p_lpn_id   
	   ,NULL -- p_content_lpn_id
	   ,p_org_id -- p_xfer_org_id  
	   ,p_subinv_code  -- p_xfer_subinv_code 
	   ,v_locator_id -- p_xfer_locator_id
	   ,NULL -- p_xfer_lpn_id
	   ,p_user_id -- p_user_id 
       ,v_receipt_txn_id 
	   ,v_returnCode 
	   ,v_returnMsg
       );

END IF;

-- -------------------------
-- Insert MOQ
-- -------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '32';

	CALL pr_wms_process_moq(
		  p_org_id 
		, p_xfer_subinv_code
		, v_xfer_locator_id 
		, p_item_id
		, NULL -- p_lpn_id 
		, p_txn_qty 
		, v_txn_uom  
		, p_user_id
		, v_returnCode
		, v_returnMsg
    );
    
END IF;

-- -------------------------
-- Insert MOQ
-- -------------------------
IF v_returnCode = 'S' THEN

   SET v_process = '40';

   CALL pr_wms_insert_mut (
	  p_org_id
	, v_receipt_txn_id
	, p_serial_no
	, v_item_id
	, p_xfer_subinv_code 
	, v_xfer_locator_id 
	, p_user_id  
	, v_returnCode 
	, v_returnMsg
   );   

END IF;

IF v_returnCode = 'S' THEN
    SET x_returnCode = 'S';
	SET x_returnMsg = v_returnMsg; 
    COMMIT;
ELSE
    SET x_returnCode = 'E';
	SET x_returnMsg = CONCAT('Error-',v_process,'-',v_returnMsg);
    ROLLBACK;
END IF;

END