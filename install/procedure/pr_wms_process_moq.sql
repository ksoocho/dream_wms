CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_process_moq`(
     IN p_org_id            INT
    ,IN p_subinv_code       VARCHAR(10) 
    ,IN p_locator_id        INT
	,IN p_item_id           INT  
	,IN p_lpn_id            INT  
    ,IN p_txn_qty           INT
    ,IN p_txn_uom           VARCHAR(3)
    ,IN p_user_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_insert_mo
-- Description    : Insert MOQ
-- 2016/03/06 ksoocho 최초 작성
-- **********************************************

DECLARE v_lpn_flag     VARCHAR(1); 
DECLARE v_onhand_qty   INT DEFAULT 0;  
DECLARE v_txn_qty      INT DEFAULT 0;  

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_return_value INT;
DECLARE v_check_count  INT DEFAULT 0;  

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
   OR ( p_item_id IS NULL ) THEN
       
	SET v_returnCode = 'E';
	SET v_returnMsg = 'Input Parameter'; 

END IF;  

-- Check - Subinventory / Locator
IF v_returnCode = 'S' THEN

	SET v_process = '1000';

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

	SET v_process = '100';

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
	IF p_lpn_id IS NOT NULL THEN
    
        SELECT f_wms_check_lpn(
				p_org_id
			   ,p_lpn_id)
		INTO v_return_value; 
		
		IF v_return_value < 0 THEN
			SET v_returnCode = 'E';
			SET v_returnMsg = 'Invalid LPN'; 
		END IF;
		
	END IF;
END IF;

-- --------------------------
-- Transaction ID
-- --------------------------
SET v_process = '2000';

IF v_returnCode = 'S' THEN

    IF p_lpn_id IS NULL THEN
    
		SELECT COUNT(*)
		INTO   v_check_count
		FROM cks_wms_moq moq
		WHERE moq.ORGANIZATION_ID  = p_org_id
		AND   moq.INVENTORY_ITEM_ID = p_item_id
		AND   moq.SUBINVENTORY_CODE = p_subinv_code
		AND   moq.LOCATOR_ID = p_locator_id
		AND   moq.LPN_ID IS NULL;
        
        SET v_lpn_flag = 'N';
        
    ELSE
    
		SELECT COUNT(*)
		INTO   v_check_count
		FROM cks_wms_moq moq
		WHERE moq.ORGANIZATION_ID  = p_org_id
		AND   moq.INVENTORY_ITEM_ID = p_item_id
		AND   moq.SUBINVENTORY_CODE = p_subinv_code
		AND   moq.LOCATOR_ID = p_locator_id
		AND   moq.LPN_ID = p_lpn_id;

        SET v_lpn_flag = 'Y';

    END IF;
    
    IF v_check_count = 0 THEN

        SET v_process = '3100';
    
		INSERT INTO cks_wms_moq
		(ORGANIZATION_ID 
		,INVENTORY_ITEM_ID
		,SUBINVENTORY_CODE
		,LOCATOR_ID
		,LPN_ID  
		,PRIMARY_TRANSACTION_QUANTITY
		,TRANSACTION_QUANTITY 
		,TRANSACTION_UOM_CODE 
		,DATE_RECEIVED  
		,CREATION_DATE 
		,CREATED_BY   
		,LAST_UPDATE_DATE   
		,LAST_UPDATED_BY   
		) VALUES (
		  p_org_id
		 ,p_item_id
		 ,p_subinv_code
		 ,p_locator_id
		 ,p_lpn_id
		 ,p_txn_qty  
		 ,p_txn_qty  
		 ,p_txn_uom  
		 ,SYSDATE() -- DATE_RECEIVED 
		 ,SYSDATE()
		 ,p_user_id
		 ,SYSDATE()
		 ,p_user_id    
		);
    
    ELSE

       SET v_process = '3200';
    
       IF v_lpn_flag = 'N' THEN

			SELECT moq.TRANSACTION_QUANTITY 
			INTO   v_onhand_qty
			FROM cks_wms_moq moq
			WHERE moq.ORGANIZATION_ID  = p_org_id
			AND   moq.INVENTORY_ITEM_ID = p_item_id
			AND   moq.SUBINVENTORY_CODE = p_subinv_code
			AND   moq.LOCATOR_ID = p_locator_id
			AND   moq.LPN_ID IS NULL;

            SET v_txn_qty = v_onhand_qty + p_txn_qty;
            
            IF v_txn_qty = 0 THEN

				DELETE FROM cks_wms_moq
				WHERE ORGANIZATION_ID  = p_org_id
				AND   INVENTORY_ITEM_ID = p_item_id
				AND   SUBINVENTORY_CODE = p_subinv_code
				AND   LOCATOR_ID = p_locator_id
				AND   LPN_ID IS NULL;
            
            ELSEIF v_txn_qty > 0 THEN
       
				UPDATE cks_wms_moq moq
				   SET PRIMARY_TRANSACTION_QUANTITY = v_txn_qty
					  ,TRANSACTION_QUANTITY  = v_txn_qty
					  ,TRANSACTION_UOM_CODE  = p_txn_uom  
					  ,DATE_RECEIVED = SYSDATE()
					  ,LAST_UPDATE_DATE  = SYSDATE() 
					  ,LAST_UPDATED_BY  = p_user_id
				WHERE moq.ORGANIZATION_ID  = p_org_id
				AND   moq.INVENTORY_ITEM_ID = p_item_id
				AND   moq.SUBINVENTORY_CODE = p_subinv_code
				AND   moq.LOCATOR_ID = p_locator_id
				AND   moq.LPN_ID IS NULL;
            
            ELSE
                SET v_returnCode = 'E';
	            SET v_returnMsg = 'Invalid Quantity'; 
            END IF;
        
       ELSE

            SELECT moq.TRANSACTION_QUANTITY 
			INTO   v_onhand_qty
			FROM cks_wms_moq moq
			WHERE moq.ORGANIZATION_ID  = p_org_id
			AND   moq.INVENTORY_ITEM_ID = p_item_id
			AND   moq.SUBINVENTORY_CODE = p_subinv_code
			AND   moq.LOCATOR_ID = p_locator_id
			AND   moq.LPN_ID = p_lpn_id;

            SET v_txn_qty = v_onhand_qty + p_txn_qty;
            
            IF v_txn_qty = 0 THEN

				DELETE FROM cks_wms_moq
				WHERE ORGANIZATION_ID  = p_org_id
				AND   INVENTORY_ITEM_ID = p_item_id
				AND   SUBINVENTORY_CODE = p_subinv_code
				AND   LOCATOR_ID = p_locator_id
				AND   LPN_ID = p_lpn_id;
            
            ELSEIF v_txn_qty > 0 THEN

				UPDATE cks_wms_moq moq
				   SET PRIMARY_TRANSACTION_QUANTITY = v_txn_qty
					  ,TRANSACTION_QUANTITY  = v_txn_qty
					  ,TRANSACTION_UOM_CODE  = p_txn_uom  
					  ,DATE_RECEIVED = SYSDATE()
					  ,LAST_UPDATE_DATE  = SYSDATE() 
					  ,LAST_UPDATED_BY  = p_user_id
				WHERE moq.ORGANIZATION_ID  = p_org_id
				AND   moq.INVENTORY_ITEM_ID = p_item_id
				AND   moq.SUBINVENTORY_CODE = p_subinv_code
				AND   moq.LOCATOR_ID = p_locator_id
				AND   moq.LPN_ID = p_lpn_id;

            ELSE
                SET v_returnCode = 'E';
	            SET v_returnMsg = 'Invalid Quantity'; 
            
            END IF;
       
       END IF;
    
    END IF;
    
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