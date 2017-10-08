CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_bom_generate`(
      IN p_org_id            INT
    , IN p_assem_item_code   VARCHAR(40)
    , IN p_comp_item_code    VARCHAR(40)
    , IN p_comp_qty          INT
 	, IN p_comp_remark       VARCHAR(240)  
    , IN p_user_id           INT
	, OUT x_returnCode       VARCHAR(5)
 	, OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_bom_generate
-- Description    : BOM Generate
-- 2016/03/06   ksoocho   최초 작성
-- **********************************************
DECLARE v_assem_item_id     INT;
DECLARE v_comp_item_id      INT;
DECLARE v_bom_seq_id        INT;
DECLARE v_item_num          INT;
DECLARE v_bom_enabled_flag  VARCHAR(1);

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_check_count  INT;

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

IF ( p_org_id IS NULL ) 
    OR ( p_assem_item_code IS NULL ) 
    OR ( p_comp_item_code IS NULL ) 
    OR ( p_comp_qty IS NULL ) 
    OR ( p_comp_qty <= 0 )THEN

   SET v_returnCode = 'E';
   SET v_returnMsg = 'Invalid Parameter'; 

END IF;

-- Get Assembly Item ID
IF v_returnCode = 'S' THEN

	SET v_process = '11';

    SELECT f_wms_get_item_id(
            p_org_id
           ,p_assem_item_code)
    INTO v_assem_item_id; 

    IF v_assem_item_id < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Assembly Item'; 
    END IF;

END IF;

-- Get Component Item ID
IF v_returnCode = 'S' THEN

	SET v_process = '11';

    SELECT f_wms_get_item_id(
            p_org_id
           ,p_comp_item_code)
    INTO v_comp_item_id; 

    IF v_comp_item_id < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Component Item'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

	SELECT BOM_ENABLED_FLAG
	INTO v_bom_enabled_flag
	FROM cks_wms_item msib
	WHERE msib.ORGANIZATION_ID  = p_org_id
	AND   msib.INVENTORY_ITEM_ID  = v_assem_item_id;
    
    IF v_bom_enabled_flag = 'N' THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Assembly Item (BOM)'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

	SELECT BOM_ENABLED_FLAG
	INTO v_bom_enabled_flag
	FROM cks_wms_item msib
	WHERE msib.ORGANIZATION_ID  = p_org_id
	AND   msib.INVENTORY_ITEM_ID  = v_comp_item_id;
    
    IF v_bom_enabled_flag = 'N' THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Component Item (BOM)'; 
    END IF;

END IF;


-- Check BOM
IF v_returnCode = 'S' THEN

    START TRANSACTION;

    SELECT COUNT(*)
    INTO   v_check_count
    FROM   cks_wms_bom
    WHERE  ORGANIZATION_ID = p_org_id
    AND    ASSEMBLY_ITEM_ID = v_assem_item_id;

    IF  v_check_count = 0 THEN
		INSERT INTO cks_wms_bom
		( ORGANIZATION_ID
         ,ASSEMBLY_ITEM_ID
         ,ASSEMBLY_TYPE
         ,CREATION_DATE
         ,CREATED_BY
         ,LAST_UPDATE_DATE
         ,LAST_UPDATED_BY
		) VALUES (
		  p_org_id
          ,v_assem_item_id
          ,1 -- Manufacturing BOM
		  ,SYSDATE()
          ,p_user_id
          ,SYSDATE()
          ,p_user_id);   
          
         SET v_bom_seq_id = LAST_INSERT_ID(); 
    ELSE    
		SELECT BILL_SEQUENCE_ID
		INTO   v_bom_seq_id
		FROM   cks_wms_bom
		WHERE  ORGANIZATION_ID = p_org_id
		AND    ASSEMBLY_ITEM_ID = v_assem_item_id;
    END IF;

    -- --------------------------
    -- BOM Component
    -- --------------------------
    SELECT COUNT(*)
    INTO  v_check_count
    FROM  cks_wms_bic
    WHERE BILL_SEQUENCE_ID = v_bom_seq_id
    AND   COMPONENT_ITEM_ID = v_comp_item_id;
    
    IF v_check_count = 0 THEN
    
       SET v_item_num = v_check_count + 1;
    
       INSERT INTO  cks_wms_bic
       ( BILL_SEQUENCE_ID 
        ,COMPONENT_ITEM_ID
        ,ITEM_NUM     
        ,COMPONENT_QUANTITY 
        ,EFFECTIVITY_DATE
        ,DISABLE_DATE  
        ,COMPONENT_REMARKS    
        ,CREATION_DATE
        ,CREATED_BY 
        ,LAST_UPDATE_DATE 
        ,LAST_UPDATED_BY
       ) VALUES (
         v_bom_seq_id
         ,v_comp_item_id
         ,v_item_num
         ,p_comp_qty
         ,SYSDATE()
         ,NULL
         ,p_comp_remark
         ,SYSDATE()
         ,p_user_id
         ,SYSDATE()
         ,p_user_id
       );
    
    ELSE

        SET v_returnCode = 'E';
	    SET v_returnMsg = 'Already Exist BOM';     
        
    END IF;



END IF;


END