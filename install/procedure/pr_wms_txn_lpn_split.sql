CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_txn_lpn_split`(
     IN p_org_id            INT
    ,IN p_subinv_code       VARCHAR(10) 
    ,IN p_locator_id        INT
	,IN p_item_id           INT  
    ,IN p_lpn_code          VARCHAR(30) 
    ,IN p_xfer_lpn_code     VARCHAR(30) 
    ,IN p_txn_qty           INT
    ,IN p_txn_uom           VARCHAR(3)
    ,IN p_txn_reference     VARCHAR(240)  
    ,IN p_user_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_txn_lpn_split
-- Description    : LPN Split ( No Serial Control )
-- 2016/03/06 ksoocho 최초 작성
-- **********************************************
DECLARE v_lpn_id           INT;
DECLARE v_xfer_lpn_id      INT;
DECLARE v_xfer_lpn_context INT;
DECLARE v_xfer_loc_id      INT; 

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

	SET v_process = '11';

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

	SET v_process = '12';

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

	SET v_process = '13';

    SELECT f_wms_get_lpn_id(
            p_org_id
           ,p_lpn_code)
    INTO v_lpn_id; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid LPN'; 
    END IF;

END IF;

-- Check - Pack LPN ( 1 )
IF v_returnCode = 'S' THEN

	SET v_process = '14';

    SELECT f_wms_check_lpn(
            p_org_id
           ,v_lpn_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid LPN'; 
    END IF;

END IF;

-- Check - LPN
IF v_returnCode = 'S' THEN

	SET v_process = '15';

    SELECT f_wms_get_lpn_id(
            p_org_id
           ,p_xfer_lpn_code)
    INTO v_xfer_lpn_id; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Source LPN'; 
    END IF;

END IF;

-- Check - Pack LPN ( 1, 5)
IF v_returnCode = 'S' THEN

	SET v_process = '16';

    SELECT f_wms_check_pack_lpn(
            p_org_id
           ,v_xfer_lpn_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Target LPN'; 
    END IF;

END IF;

-- 동일한 Locator 내에서만 Split 가능
IF v_returnCode = 'S' THEN

	SET v_process = '17';

	SELECT lpn.LPN_CONTEXT
		  ,lpn.LOCATOR_ID
	INTO  v_xfer_lpn_context
		 ,v_xfer_loc_id      
	FROM cks_wms_lpn lpn
	WHERE lpn.LPN_ID = v_xfer_lpn_id;    

	IF v_xfer_lpn_context = 1 THEN

	   IF p_locator_id <> v_xfer_loc_id THEN
			SET v_returnCode = 'E';
			SET v_returnMsg = 'Target LPN - Different Locator '; 
	   END IF;

	END IF;

END IF;

-- -------------------------
-- Unpack
-- -------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '21';

    START TRANSACTION;

    CALL pr_wms_process_lpn_txn(
      2 -- p_process_mode - UnPack
    , 89 -- p_txn_type_id - Container Split 
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

-- -------------------------
-- Pack
-- -------------------------
IF v_returnCode = 'S' THEN

	SET v_process = '22';

    CALL pr_wms_process_lpn_txn(
      1 -- p_process_mode - Pack
    , 89 -- p_txn_type_id - Container Split 
    , p_org_id   
    , p_subinv_code  
    , p_locator_id
	, p_item_id  
    , NULL -- p_from_lpn_id  
    , v_xfer_lpn_id -- p_xfer_lpn_id  
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