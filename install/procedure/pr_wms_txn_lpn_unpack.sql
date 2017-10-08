CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_txn_lpn_unpack`(
     IN p_org_id            INT
    ,IN p_subinv_code       VARCHAR(10) 
    ,IN p_locator_id        INT
	,IN p_item_id           INT  
    ,IN p_lpn_code          VARCHAR(30) 
    ,IN p_txn_qty           INT
    ,IN p_txn_uom           VARCHAR(3)
    ,IN p_txn_reference     VARCHAR(50)  
    ,IN p_user_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_lpn_unpack
-- Description    : LPN UnPack ( No Serial Control )
-- 2016/03/06 ksoocho 최초 작성
-- **********************************************
DECLARE v_txn_type_id  INT;
DECLARE v_txn_id       INT;
DECLARE v_lpn_id       INT;

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

-- Check - Subinventory / Locator
IF v_returnCode = 'S' THEN

	SET v_process = '10';

    SELECT f_wms_check_locator(
            p_org_id
           ,p_subinv_code
           ,p_locator_id)
    INTO v_return_value; 

    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Locator'; 
    END IF;

END IF;

-- Check - Organization Item
IF v_returnCode = 'S' THEN

	SET v_process = '20';

    SELECT f_wms_check_item(
            p_org_id
           ,p_item_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Item'; 
    END IF;

END IF;

-- Check - LPN
IF v_returnCode = 'S' THEN

	SET v_process = '20';

    SELECT f_wms_get_lpn_id(
            p_org_id
           ,p_lpn_code)
    INTO v_lpn_id; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid LPN'; 
    END IF;

END IF;

-- Check - Pack LPN ( 1, 5)
IF v_returnCode = 'S' THEN

	SET v_process = '20';

    SELECT f_wms_check_lpn(
            p_org_id
           ,v_lpn_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid LPN'; 
    END IF;

END IF;

-- -------------------------
-- Insert MMT
-- -------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '30';

    START TRANSACTION;

    CALL pr_wms_process_lpn_txn(
     2 -- p_process_mode - UnPack
    ,88 -- p_txn_type_id - Container Unpack 
    , p_org_id   
    , p_subinv_code  
    , p_locator_id
	, p_item_id  
    , v_lpn_id -- p_from_lpn_id  
    , NULL -- p_xfer_lpn_id  
    , NULL -- p_cnt_lpn_id 
    , p_txn_qty       
    , p_txn_uom       
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