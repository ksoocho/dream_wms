CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_txn_issue_lpn`(
     IN p_org_id            INT
    ,IN p_subinv_code       VARCHAR(10) 
    ,IN p_locator_code      VARCHAR(40) 
	,IN p_item_code         VARCHAR(40)  
    ,IN p_lpn_code          VARCHAR(30) 
    ,IN p_txn_qty           INT
	,IN p_txn_type_id       INT  
    ,IN p_txn_reference     VARCHAR(240)  
    ,IN p_user_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_misc_receipt
-- Description    : 입고처리 ( No Serial Control )
-- 2016/03/06 ksoocho 최초 작성
-- **********************************************
DECLARE v_locator_id        INT;
DECLARE v_item_id           INT;
DECLARE v_txn_type_id       INT;
DECLARE v_lpn_id            INT;
DECLARE v_txn_uom           VARCHAR(3);

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

IF ( p_org_id IS NULL ) 
   OR ( p_subinv_code IS NULL ) 
   OR ( p_locator_code IS NULL ) 
   OR ( p_item_code IS NULL ) 
   OR ( p_txn_qty IS NULL ) 
   OR ( p_txn_qty <= 0 ) THEN
   SET v_returnCode = 'E';
   SET v_returnMsg = 'Invalid Parameter'; 
END IF;

-- ------------------------------------
-- Check - Transaction Type
--  32 - Misc Issue
--  33 - Sales Order Issue
--  35 - WIP Issue
--  36 - Return to Vendor
-- ------------------------------------
IF p_txn_type_id IS NULL THEN
   SET v_txn_type_id = 32;
ELSE
   SET v_txn_type_id = p_txn_type_id;
END IF;

IF v_returnCode = 'S' THEN

   IF  v_txn_type_id NOT IN ( 1, 31, 32, 33, 35 ) THEN
	   SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Transaction Type';    
   END IF;

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

-- Get Item ID
IF v_returnCode = 'S' THEN

	SET v_process = '12';

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

	SET v_process = '13';

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

-- Check - Organization Item
IF v_returnCode = 'S' THEN

	SET v_process = '14';

    SELECT f_wms_check_item(
            p_org_id
           ,v_item_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Item'; 
    END IF;

END IF;

-- Check - Serial Item
IF v_returnCode = 'S' THEN

	SET v_process = '15';

    SELECT f_wms_check_item_serial(
            p_org_id
           ,v_item_id)
    INTO v_return_value; 
    
    IF v_return_value = 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Serial Item'; 
    END IF;

END IF;

-- Check - LPN
IF v_returnCode = 'S' THEN

	SET v_process = '16';

    SELECT f_wms_get_lpn_id(
            p_org_id
           ,p_lpn_code)
    INTO v_lpn_id; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid LPN'; 
    END IF;

END IF;

-- Check - LPN
IF v_returnCode = 'S' THEN

	SET v_process = '17';

	SELECT f_wms_check_lpn(
			p_org_id
		   ,v_lpn_id)
	INTO v_return_value; 
	
	IF v_return_value < 0 THEN
		SET v_returnCode = 'E';
		SET v_returnMsg = 'Invalid LPN'; 
	END IF;
    

END IF;

IF v_returnCode = 'S' THEN

	SET v_process = '20';

    START TRANSACTION;

    CALL pr_wms_process_lpn_txn(
			 7 -- p_process_mode - Issue
			, v_txn_type_id 
			, p_org_id   
			, p_subinv_code  
			, v_locator_id
			, v_item_id  
			, NULL -- p_from_lpn_id  
			, NULL -- p_xfer_lpn_id  
			, v_lpn_id -- p_cnt_lpn_id 
			, p_txn_qty       
			, v_txn_uom       
			, NULL -- p_to_subinv_code 
			, NULL -- p_to_locator_id 
			, p_txn_reference
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