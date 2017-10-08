CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_process_lpn_txn`(
     IN p_process_mode      INT
    ,IN p_txn_type_id       INT
    ,IN p_org_id            INT
    ,IN p_subinv_code       VARCHAR(10) 
    ,IN p_locator_id        INT
	,IN p_item_id           INT  
    ,IN p_from_lpn_id       INT 
    ,IN p_xfer_lpn_id       INT 
    ,IN p_cnt_lpn_id        INT 
    ,IN p_txn_qty           INT
    ,IN p_txn_uom           VARCHAR(3)
    ,IN p_to_subinv_code    VARCHAR(10) 
    ,IN p_to_locator_id     INT
    ,IN p_txn_reference     VARCHAR(50) 
    ,IN p_user_id           INT
	,OUT x_returnCode       VARCHAR(5)
 	,OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_process_lpn_txn
-- Description    : Process LPN Transaction
-- 2016/03/06   ksoocho   최초 작성
-- **********************************************
DECLARE v_onhand_loose_qty   INT;
DECLARE v_onhand_packed_qty  INT;
DECLARE v_txn_id             INT;  

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


-- ***************************************
-- Container Pack
-- p_xfer_lpn_id
-- ***************************************
IF p_process_mode  = 1 THEN

	-- Check - Onhand Loose Qty
	IF v_returnCode = 'S' THEN

		SET v_process = '200';

		SELECT f_wms_get_onhand_loose_qty(
				p_org_id 
			   ,p_subinv_code
			   ,p_locator_id 
			   ,p_item_id)
		INTO v_onhand_loose_qty; 
		
		IF ( v_onhand_loose_qty - p_txn_qty ) < 0 THEN
			SET v_returnCode = 'E';
			SET v_returnMsg = 'Invalid Onhand Qty'; 
		END IF;

	END IF;

	-- ----------------------------
	-- MOQ Update
	-- loose qty 감소 + packed qty 증가
	-- ----------------------------
    IF ( p_txn_type_id <> 89 ) THEN  -- Split 제외 처리

		IF v_returnCode = 'S' THEN

			SET v_process = '310';

			CALL pr_wms_insert_mmt(
				p_org_id  
			   ,p_subinv_code 
			   ,p_locator_id 
			   ,p_item_id  
			   ,p_txn_type_id  -- v_txn_type_id - Container Pack
			   ,p_txn_qty * (-1) 
			   ,p_txn_uom  
			   ,p_txn_reference 
			   ,NULL -- p_lpn_id   
			   ,NULL -- p_content_lpn_id
			   ,NULL -- p_xfer_org_id  
			   ,NULL -- p_xfer_subinv_code 
			   ,NULL -- p_xfer_locator_id
			   ,NULL -- p_xfer_lpn_id
			   ,p_user_id -- p_user_id 
			   ,v_txn_id 
			   ,v_returnCode 
			   ,v_returnMsg
			   );

		END IF;
		
		IF v_returnCode = 'S' THEN

		   SET v_process = '320';

		   CALL pr_wms_process_moq(
			 p_org_id 
			,p_subinv_code
			,p_locator_id 
			,p_item_id  
			,NULL -- p_lpn_id   
			,p_txn_qty * -1   -- loose qty 감소
			,p_txn_uom   
			,p_user_id   
			,v_returnCode 
			,v_returnMsg
		   );

		END IF;

		IF v_returnCode = 'S' THEN

			SET v_process = '330';

			CALL pr_wms_insert_mmt(
				p_org_id  
			   ,p_subinv_code 
			   ,p_locator_id 
			   ,p_item_id  
			   ,p_txn_type_id  -- v_txn_type_id - Container Pack
			   ,p_txn_qty  
			   ,p_txn_uom  
			   ,p_txn_reference 
			   ,NULL -- p_lpn_id   
			   ,NULL -- p_content_lpn_id
			   ,NULL -- p_xfer_org_id  
			   ,NULL -- p_xfer_subinv_code 
			   ,NULL -- p_xfer_locator_id
			   ,p_xfer_lpn_id -- p_xfer_lpn_id
			   ,p_user_id -- p_user_id 
			   ,v_txn_id 
			   ,v_returnCode 
			   ,v_returnMsg
			   );

		END IF;
    
    END IF;
    
    IF v_returnCode = 'S' THEN

       SET v_process = '340';

       CALL pr_wms_process_moq(
         p_org_id 
		,p_subinv_code
		,p_locator_id 
		,p_item_id  
		,p_xfer_lpn_id   
		,p_txn_qty   -- packed qty 증가
		,p_txn_uom   
		,p_user_id   
		,v_returnCode 
		,v_returnMsg
       );

    END IF;
    
    -- LPN Contents
    IF v_returnCode = 'S' THEN

        SET v_process = '350';

		CALL pr_wms_lpn_content (
             p_process_mode
			,p_org_id
		    ,p_subinv_code
		    ,p_locator_id 
			,p_xfer_lpn_id
			,p_item_id
			,p_txn_qty 
			,p_txn_uom 
			,p_user_id
			,v_returnCode 
			,v_returnMsg
			);
    END IF;
    
    -- LPN History
    IF v_returnCode = 'S' THEN

        SET v_process = '360';
    
		CALL pr_wms_lpn_history (
			p_org_id        
			,p_xfer_lpn_id       
			,p_item_id        
			,NULL -- p_serial_number   
			,p_txn_qty           
			,p_txn_uom            
			,p_subinv_code    
			,p_locator_id     
			,NULL -- p_to_serial_number
			,p_process_mode -- Action Type (Pack)
			,v_txn_id           
			,p_user_id        
			,v_returnCode      
			,v_returnMsg       
			);
            
    END IF;         

END IF;

-- ***************************************
-- Container UnPack
-- p_from_lpn_id
-- ***************************************
IF p_process_mode  = 2 THEN

	-- Check - Onhand Packed Qty
	IF v_returnCode = 'S' THEN

		SET v_process = '200';

		SELECT f_wms_get_onhand_packed_qty(
				p_org_id 
			   ,p_subinv_code
			   ,p_locator_id 
			   ,p_item_id)
		INTO v_onhand_packed_qty; 
		
		IF ( v_onhand_packed_qty - p_txn_qty ) < 0 THEN
			SET v_returnCode = 'E';
			SET v_returnMsg = 'Invalid Onhand Qty'; 
		END IF;

	END IF;

	-- ----------------------------
    -- MOQ Update
    -- Unpack : loose qty 증가 + packed qty 감소
	-- ----------------------------

    IF ( p_txn_type_id <> 89 ) THEN  -- Split 제외 처리

		IF v_returnCode = 'S' THEN

			SET v_process = '410';

			CALL pr_wms_insert_mmt(
				p_org_id  
			   ,p_subinv_code 
			   ,p_locator_id 
			   ,p_item_id  
			   ,p_txn_type_id  -- v_txn_type_id - Container UnPack
			   ,p_txn_qty 
			   ,p_txn_uom  
			   ,p_txn_reference 
			   ,NULL -- p_lpn_id   
			   ,NULL -- p_content_lpn_id
			   ,NULL -- p_xfer_org_id  
			   ,NULL -- p_xfer_subinv_code 
			   ,NULL -- p_xfer_locator_id
			   ,NULL -- p_xfer_lpn_id
			   ,p_user_id -- p_user_id 
			   ,v_txn_id 
			   ,v_returnCode 
			   ,v_returnMsg
			   );

		END IF;
		
		IF v_returnCode = 'S' THEN

		   SET v_process = '420';

		   CALL pr_wms_process_moq(
			 p_org_id 
			,p_subinv_code
			,p_locator_id 
			,p_item_id  
			,NULL -- p_lpn_id   
			,p_txn_qty   -- loose qty 증가
			,p_txn_uom   
			,p_user_id   
			,v_returnCode 
			,v_returnMsg
		   );

		END IF;
		
    END IF;

	IF v_returnCode = 'S' THEN

        SET v_process = '430';

		CALL pr_wms_insert_mmt(
			p_org_id  
		   ,p_subinv_code 
		   ,p_locator_id 
		   ,p_item_id  
		   ,p_txn_type_id  -- v_txn_type_id - Container UnPack
		   ,p_txn_qty * (-1)
		   ,p_txn_uom  
		   ,p_txn_reference 
		   ,p_from_lpn_id -- p_lpn_id   
		   ,NULL -- p_content_lpn_id
		   ,NULL -- p_xfer_org_id  
		   ,NULL -- p_xfer_subinv_code 
		   ,NULL -- p_xfer_locator_id
		   ,NULL  -- p_xfer_lpn_id
		   ,p_user_id -- p_user_id 
		   ,v_txn_id 
		   ,v_returnCode 
		   ,v_returnMsg
		   );

	END IF;
    
     IF v_returnCode = 'S' THEN

       SET v_process = '440';

       CALL pr_wms_process_moq(
         p_org_id 
		,p_subinv_code
		,p_locator_id 
		,p_item_id  
		,p_from_lpn_id   
		,p_txn_qty * (-1)  -- packed qty 감소
		,p_txn_uom   
		,p_user_id   
		,v_returnCode 
		,v_returnMsg
       );

    END IF;
    
    -- LPN Contents
    IF v_returnCode = 'S' THEN

        SET v_process = '450';

		CALL pr_wms_lpn_content (
             p_process_mode
			,p_org_id
		    ,p_subinv_code
		    ,p_locator_id 
			,p_from_lpn_id
			,p_item_id
			,p_txn_qty * (-1) -- wlc qty 감소
			,p_txn_uom 
			,p_user_id
			,v_returnCode 
			,v_returnMsg
			);
    END IF;
    
    -- LPN History
    IF v_returnCode = 'S' THEN

        SET v_process = '460';
    
		CALL pr_wms_lpn_history (
			p_org_id        
			,p_from_lpn_id       
			,p_item_id        
			,NULL -- p_serial_number   
			,p_txn_qty           
			,p_txn_uom            
			,p_subinv_code    
			,p_locator_id     
			,NULL -- p_to_serial_number
			,p_process_mode -- Action Type (Pack)
			,v_txn_id           
			,p_user_id        
			,v_returnCode      
			,v_returnMsg       
			);
            
    END IF;      

END IF;

-- ***************************************
-- LPN Issue
--   p_cnt_lpn_id
--   LPN 분할출고 불가
-- ***************************************
IF p_process_mode  = 7 THEN

	-- Check - Onhand Packed Qty
	IF v_returnCode = 'S' THEN

		SET v_process = '200';

		SELECT f_wms_get_onhand_packed_qty(
				p_org_id 
			   ,p_subinv_code
			   ,p_locator_id 
			   ,p_item_id)
		INTO v_onhand_packed_qty; 
		
		IF ( v_onhand_packed_qty - p_txn_qty ) < 0 THEN
			SET v_returnCode = 'E';
			SET v_returnMsg = 'Invalid Onhand Qty'; 
		ELSEIF ( v_onhand_packed_qty - p_txn_qty ) > 0 THEN  
			SET v_returnCode = 'E';
			SET v_returnMsg = 'Invalid Transaction Qty'; 
		END IF;

	END IF;

    IF v_returnCode = 'S' THEN
		-- -------------------------
		-- Insert MMT  ( LPN )
		-- -------------------------
		CALL pr_wms_insert_mmt(
			p_org_id  
		   ,p_subinv_code 
		   ,p_locator_id 
		   ,p_item_id  
		   ,p_txn_type_id 
		   ,p_txn_qty * (-1) 
		   ,p_txn_uom  
		   ,p_txn_reference 
		   ,NULL -- p_lpn_id   
		   ,p_cnt_lpn_id -- p_content_lpn_id
		   ,NULL -- p_xfer_org_id  
		   ,NULL -- p_xfer_subinv_code 
		   ,NULL -- p_xfer_locator_id
		   ,NULL -- p_xfer_lpn_id
		   ,p_user_id -- p_user_id 
		   ,v_txn_id 
		   ,v_returnCode 
		   ,v_returnMsg
		   );
           
    END IF;
    
	-- -------------------------
	-- Insert MOQ ( LPN )
	-- -------------------------
	IF v_returnCode = 'S' THEN

		SET v_process = '6000';

		CALL pr_wms_process_moq(
			  p_org_id 
			, p_subinv_code
			, p_locator_id 
			, p_item_id
			, p_cnt_lpn_id
			, p_txn_qty * (-1) 
			, p_txn_uom  
			, p_user_id
			, v_returnCode
			, v_returnMsg
		);
		
	END IF;     
    
	-- LPN Contents
	IF v_returnCode = 'S' THEN
		CALL pr_wms_lpn_content (
			 p_process_mode -- Issue Out
			,p_org_id
			,p_cnt_lpn_id
			,p_item_id
			,p_txn_qty 
			,p_txn_uom 
			,p_user_id
			,v_returnCode 
			,v_returnMsg
			);
	END IF;
	
	-- LPN History
	IF v_returnCode = 'S' THEN
		CALL pr_wms_lpn_history (
			p_org_id        
			,p_cnt_lpn_id  
			,p_item_id        
			,NULL -- p_serial_number   
			,p_txn_qty           
			,p_txn_uom            
			,p_subinv_code    
			,p_locator_id     
			,NULL -- p_to_serial_number
			,p_process_mode -- p_operation_mode - Issue Out
			,p_txn_id           
			,p_user_id        
			,v_returnCode      
			,v_returnMsg       
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