CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_lpn_history`(
    IN p_org_id            INT,
    IN p_lpn_id            INT,
    IN p_item_id           INT,
    IN p_serial_number     VARCHAR(30),
    IN p_txn_qty               INT,
    IN p_txn_uom               VARCHAR(10),
    IN p_subinv_code       VARCHAR(20),
    IN p_locator_id        INT,
    IN p_to_serial_number  VARCHAR(30),
    IN p_operation_mode    INT,
    IN p_txn_id            INT,
    IN p_user_id           INT,
	OUT x_returnCode       VARCHAR(5),
 	OUT x_returnMsg        VARCHAR(255)
)
BEGIN

DECLARE v_parent_lpn_id       INT;
DECLARE v_outermost_lpn_id    INT;
DECLARE v_lpn_context         INT;

DECLARE v_parent_lpn_code  VARCHAR(30);
DECLARE v_lpn_code         VARCHAR(30);

DECLARE v_serial_number VARCHAR(30);
DECLARE v_data_count    INT;

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_check_count  INT DEFAULT 0;  

DECLARE done INT DEFAULT FALSE;

-- 커서 - Serial Number
DECLARE c_serial CURSOR FOR 
	SELECT serial_number
	FROM cks_wms_mut mut
	WHERE mut.transaction_id = p_txn_id;

-- 커서가 마지막에 도착할 때의 상태값
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
  
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
   OR ( p_lpn_id IS NULL ) THEN
       
	SET v_returnCode = 'E';
	SET v_returnMsg = 'Input Parameter'; 

END IF;  

-- Get LPN Code
IF p_lpn_id IS NOT NULL THEN

    SELECT f_wms_get_lpn_code(
            p_org_id
           ,p_lpn_id)
    INTO v_lpn_code; 

	SELECT PARENT_LPN_ID
		  ,OUTERMOST_LPN_ID
          ,LPN_CONTEXT
	INTO  v_parent_lpn_id
		 ,v_outermost_lpn_id
         ,v_lpn_context
	FROM cks_wms_lpn
	WHERE LPN_ID = p_lpn_id
	AND   ORGANIZATION_ID = p_org_id;
    
END IF; 

-- Get LPN Code
IF v_parent_lpn_id IS NOT NULL THEN

    SELECT f_wms_get_lpn_code(
            p_org_id
           ,v_parent_lpn_id)
    INTO v_parent_lpn_code; 
    
END IF; 

IF v_returnCode = 'S' THEN

    SELECT COUNT(*)
    INTO  v_data_count
    FROM cks_wms_mut mut
	WHERE mut.transaction_id = p_txn_id;

	IF ( v_data_count > 0 ) THEN

	   SET v_process = '2100';

	   OPEN c_serial;
	   
	   read_loop: LOOP
	   
	   FETCH c_serial INTO v_serial_number ;
	   
		INSERT INTO cks_wms_wlh
		(PARENT_LPN_ID        
		,PARENT_LICENSE_PLATE_NUMBER       
		,LPN_ID
		,LICENSE_PLATE_NUMBER 
		,SERIAL_NUMBER
		,INVENTORY_ITEM_ID       
		,TRANSACTION_QUANTITY      
		,TRANSACTION_UOM_CODE      
		,ORGANIZATION_ID
		,SUBINVENTORY_CODE
		,LOCATOR_ID  
		,OPERATION_MODE   
		,LPN_CONTEXT  
		,OUTERMOST_LPN_ID   
		,TO_SERIAL_NUMBER  
		,CREATION_DATE  
		,CREATED_BY        
		,LAST_UPDATE_DATE   
		,LAST_UPDATED_BY  
		) VALUES 
		(v_parent_lpn_id
		 ,v_parent_lpn_code
		 ,p_lpn_id
		 ,v_lpn_code 
		 ,v_serial_number
		 ,p_item_id
		 ,1 -- p_txn_qty
		 ,p_txn_uom
		 ,p_org_id
		 ,p_subinv_code
		 ,p_locator_id
		 ,p_operation_mode
		 ,v_lpn_context
		 ,v_outermost_lpn_id
		 ,v_serial_number
		 ,SYSDATE()
		 ,p_user_id
		 ,SYSDATE()
		 ,p_user_id
		);
		
		-- 커서가 마지막 로우면 Loop를 빠져나간다. 
		IF done THEN
		  LEAVE read_loop;
		END IF;
	   
	   END LOOP;
	   
	   CLOSE c_serial;

	ELSE

	   SET v_process = '2200';

		INSERT INTO cks_wms_wlh
		(PARENT_LPN_ID        
		,PARENT_LICENSE_PLATE_NUMBER       
		,LPN_ID
		,LICENSE_PLATE_NUMBER 
		,SERIAL_NUMBER
		,INVENTORY_ITEM_ID       
		,TRANSACTION_QUANTITY      
		,TRANSACTION_UOM_CODE      
		,ORGANIZATION_ID
		,SUBINVENTORY_CODE
		,LOCATOR_ID  
		,OPERATION_MODE   
		,LPN_CONTEXT  
		,OUTERMOST_LPN_ID   
		,TO_SERIAL_NUMBER  
		,CREATION_DATE  
		,CREATED_BY        
		,LAST_UPDATE_DATE   
		,LAST_UPDATED_BY  
		) VALUES 
		(v_parent_lpn_id
		 ,v_parent_lpn_code
		 ,p_lpn_id
		 ,v_lpn_code 
		 ,NULL
		 ,p_item_id
		 ,p_txn_qty
		 ,p_txn_uom
		 ,p_org_id
		 ,p_subinv_code
		 ,p_locator_id
		 ,p_operation_mode
		 ,v_lpn_context
		 ,v_outermost_lpn_id
		 ,NULL
		 ,SYSDATE()
		 ,p_user_id
		 ,SYSDATE()
		 ,p_user_id
		);  

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