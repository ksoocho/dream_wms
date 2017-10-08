CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_lpn_content`(
    IN p_process_mode      INT,
    IN p_org_id            INT,
    IN p_subinv_code       VARCHAR(10), 
    IN p_locator_id        INT,
    IN p_lpn_id            INT,
    IN p_item_id           INT,
    IN p_txn_qty           INT,
    IN p_txn_uom           VARCHAR(3),
    IN p_user_id           INT,
	OUT x_returnCode       VARCHAR(5),
 	OUT x_returnMsg        VARCHAR(255)
)
BEGIN

DECLARE v_lpn_qty      INT;
DECLARE v_txn_qty      INT;

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_check_count  INT DEFAULT 0;  
DECLARE v_return_value INT DEFAULT 0;  

DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
BEGIN
    SET x_returnCode = 'E';
    SET x_returnMsg = CONCAT('Error-',v_process,'-', 'An error has occurred');
    ROLLBACK;
END;

-- Common Code check
SET v_returnCode = 'S';
SET v_returnMsg = 'Success!!'; 

SET v_process = '1000';

IF ( p_org_id IS NULL )
   OR ( p_lpn_id IS NULL ) 
   OR ( p_item_id IS NULL ) THEN
       
	SET v_returnCode = 'E';
	SET v_returnMsg = 'Input Parameter'; 

END IF;  

-- Check - Organization Item
IF v_returnCode = 'S' THEN

	SET v_process = '1100';

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

	SET v_process = '1200';

    SELECT f_wms_check_lpn(
            p_org_id
           ,p_lpn_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid LPN'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

    SELECT COUNT(*)
    INTO   v_check_count
    FROM cks_wms_wlc
    WHERE PARENT_LPN_ID      = p_lpn_id   
    AND   INVENTORY_ITEM_ID  = p_item_id
    AND   ORGANIZATION_ID    = p_org_id;

	IF v_check_count = 0 THEN

		SET v_process = '2100';

		INSERT INTO cks_wms_wlc
		(PARENT_LPN_ID
		,INVENTORY_ITEM_ID    
		,PRIMARY_QUANTITY       
		,TRANSACTION_QUANTITY   
		,TRANSACTION_UOM_CODE   
		,ORGANIZATION_ID
		,CREATION_DATE    
		,CREATED_BY
		,LAST_UPDATE_DATE  
		,LAST_UPDATED_BY 
		) VALUES 
		(p_lpn_id
		 ,p_item_id
		 ,p_txn_qty
		 ,p_txn_qty
		 ,p_txn_uom
		 ,p_org_id
		 ,SYSDATE()
		 ,p_user_id
		 ,SYSDATE()
		 ,p_user_id
		);
        
    ELSE    

		SET v_process = '2200';
        
        SELECT TRANSACTION_QUANTITY
		INTO   v_lpn_qty
		FROM cks_wms_wlc
		WHERE PARENT_LPN_ID      = p_lpn_id   
		AND   INVENTORY_ITEM_ID  = p_item_id
		AND   ORGANIZATION_ID    = p_org_id;
        
        SET v_txn_qty =  v_lpn_qty + p_txn_qty;
        
        IF  v_txn_qty > 0 THEN
        
			UPDATE cks_wms_wlc
			   SET PRIMARY_QUANTITY      =  v_txn_qty       
				  ,TRANSACTION_QUANTITY  =  v_txn_qty      
				  ,LAST_UPDATE_DATE      = SYSDATE()
				  ,LAST_UPDATED_BY       = p_user_id
			 WHERE PARENT_LPN_ID      = p_lpn_id   
			   AND INVENTORY_ITEM_ID  = p_item_id
			   AND ORGANIZATION_ID    = p_org_id;
               
            
            UPDATE cks_wms_lpn
				   SET LPN_CONTEXT = 1 -- Resides in Inventory
                      ,SUBINVENTORY_CODE = p_subinv_code
                      ,LOCATOR_ID = p_locator_id
					  ,LAST_UPDATE_DATE  = SYSDATE()
					  ,LAST_UPDATED_BY   = p_user_id
				 WHERE LPN_ID      = p_lpn_id   
				   AND ORGANIZATION_ID    = p_org_id;   
               
        ELSEIF v_txn_qty = 0 THEN 
        
            DELETE FROM cks_wms_wlc
			 WHERE PARENT_LPN_ID      = p_lpn_id   
			   AND INVENTORY_ITEM_ID  = p_item_id
			   AND ORGANIZATION_ID    = p_org_id;
            
            IF p_process_mode = 7 THEN  -- Issue Out
            
				UPDATE cks_wms_lpn
				   SET LPN_CONTEXT = 4 -- Issued out of Stores
					  ,SUBINVENTORY_CODE = NULL
					  ,LOCATOR_ID        = NULL
					  ,LAST_UPDATE_DATE  = SYSDATE()
					  ,LAST_UPDATED_BY   = p_user_id
				 WHERE LPN_ID      = p_lpn_id   
				   AND ORGANIZATION_ID    = p_org_id;   
            ELSE
				UPDATE cks_wms_lpn
				   SET LPN_CONTEXT = 5 -- Defined but not used
					  ,LAST_UPDATE_DATE  = SYSDATE()
					  ,LAST_UPDATED_BY   = p_user_id
				 WHERE LPN_ID      = p_lpn_id   
				   AND ORGANIZATION_ID    = p_org_id;   

            END IF;   
        ELSE

			SET v_returnCode = 'E';
			SET v_returnMsg = 'Invalid Transaction Qty'; 
        
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