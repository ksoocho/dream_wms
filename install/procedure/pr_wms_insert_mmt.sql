CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_insert_mmt`(
     IN p_org_id            INT
    ,IN p_subinv_code       VARCHAR(20)
    ,IN p_locator_id        INT
    ,IN p_item_id           INT
    ,IN p_txn_type_id       INT
    ,IN p_txn_qty           INT
    ,IN p_txn_uom           VARCHAR(3)
    ,IN p_txn_reference     VARCHAR(50) 
    ,IN p_lpn_id            INT
    ,IN p_content_lpn_id    INT 
    ,IN p_xfer_org_id       INT
    ,IN p_xfer_subinv_code  VARCHAR(10)
    ,IN p_xfer_locator_id   INT
    ,IN p_xfer_lpn_id       INT 
    ,IN p_user_id           INT
    ,OUT x_txn_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

DECLARE v_txn_action_id       INT;  
DECLARE v_txn_source_type_id  INT;  

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
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
   OR ( p_txn_type_id IS NULL ) 
   OR ( p_item_id IS NULL ) THEN
       
	SET v_returnCode = 'E';
	SET v_returnMsg = 'Input Parameter'; 

END IF;  

IF v_returnCode = 'S' THEN

	SELECT TRANSACTION_ACTION_ID
          ,TRANSACTION_SOURCE_TYPE_ID
	INTO v_txn_action_id
        ,v_txn_source_type_id
	FROM  cks_wms_mtt mtt
	WHERE mtt.TRANSACTION_TYPE_ID = p_txn_type_id;
    
    IF v_txn_action_id IS NULL THEN
       SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Transaction Type ID'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

	SET v_process = '2000';

	INSERT INTO cks_wms_mmt
	(ORGANIZATION_ID     
	,SUBINVENTORY_CODE     
	,LOCATOR_ID 
	,INVENTORY_ITEM_ID     
	,TRANSACTION_TYPE_ID 
	,TRANSACTION_ACTION_ID  
	,TRANSACTION_SOURCE_TYPE_ID
	,TRANSACTION_SOURCE_ID   
	,TRANSACTION_SOURCE_NAME       
	,TRANSACTION_QUANTITY   
	,TRANSACTION_UOM        
	,PRIMARY_QUANTITY      
	,TRANSACTION_DATE        
	,TRANSACTION_REFERENCE   
	,LPN_ID             
	,CONTENT_LPN_ID     
	,TRANSFER_ORGANIZATION_ID      
	,TRANSFER_SUBINVENTORY        
	,TRANSFER_LOCATOR_ID        
	,TRANSFER_LPN_ID             
	,CREATION_DATE           
	,CREATED_BY                 
	,LAST_UPDATE_DATE          
	,LAST_UPDATED_BY           
	) VALUES 
	(p_org_id
     ,p_subinv_code
     ,p_locator_id
	 ,p_item_id
     ,p_txn_type_id
     ,v_txn_action_id
     ,v_txn_source_type_id
     ,NULL
     ,NULL
     ,p_txn_qty
     ,p_txn_uom
     ,p_txn_qty
     ,SYSDATE() -- txn_date
     ,p_txn_reference
     ,p_lpn_id
     ,p_content_lpn_id
     ,p_xfer_org_id
     ,p_xfer_subinv_code
     ,p_xfer_locator_id
     ,p_xfer_lpn_id
	 ,SYSDATE()
	 ,p_user_id
	 ,SYSDATE()
	 ,p_user_id
	);

END IF;

SET x_txn_id = LAST_INSERT_ID();

IF v_returnCode = 'S' THEN
    SET x_returnCode = 'S';
	SET x_returnMsg = v_returnMsg; 
ELSE
    SET x_returnCode = 'E';
	SET x_returnMsg = CONCAT('Error-',v_process,'-',v_returnMsg);
    ROLLBACK;
END IF;

END