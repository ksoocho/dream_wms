CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_serial_generate`(
      IN p_org_id            INT
 	, IN p_item_code         VARCHAR(40)  
    , IN p_user_id           INT
	, OUT x_serial_no        VARCHAR(30)
	, OUT x_returnCode       VARCHAR(5)
 	, OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_serial_generate
-- Description    : Serial Generate
-- 2016/03/06   ksoocho   최초 작성
-- **********************************************
DECLARE v_item_id        INT;
DECLARE v_serial_no      VARCHAR(30);
DECLARE v_serial_seq     INT;
DECLARE v_date_str       VARCHAR(6);
DECLARE v_serial_prefix  VARCHAR(2);

DECLARE v_process      VARCHAR(10);
DECLARE v_returnCode   VARCHAR(5);
DECLARE v_returnMsg    VARCHAR(255);
DECLARE v_check_count  INT;
DECLARE v_return_value INT; 

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
    OR ( p_item_code IS NULL ) THEN

   SET v_returnCode = 'E';
   SET v_returnMsg = 'Invalid Parameter'; 

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

SET v_process = '1000';

-- Check - Organization
IF v_returnCode = 'S' THEN

    SELECT f_wms_check_org(
            p_org_id)
    INTO v_return_value; 

    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Organization'; 
    END IF;

END IF; 

-- Check - Organization Item
IF v_returnCode = 'S' THEN

	SET v_process = '12';

    SELECT f_wms_check_item_serial(
            p_org_id
           ,v_item_id)
    INTO v_return_value; 
    
    IF v_return_value < 0 THEN
	    SET v_returnCode = 'E';
	    SET v_returnMsg = 'Invalid Item'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

	SELECT concat(substr(IFNULL(micg.SEGMENT1,'O'),1,1)
                  ,substr(IFNULL(micg.SEGMENT2,'O'),1,1))
	INTO v_serial_prefix
    FROM cks_wms_item msib
		,cks_wms_micg micg
	WHERE msib.organization_id = p_org_id
	AND   msib.INVENTORY_ITEM_ID = v_item_id
	AND   micg.ITEM_CATALOG_GROUP_ID = msib.ITEM_CATALOG_GROUP_ID;

END IF;

IF v_returnCode = 'S' THEN

    START TRANSACTION; 

    SET v_process = '2000';

    -- YYMMDD
	SELECT DATE_FORMAT(sysdate(), '%y%m%d')
	INTO v_date_str;

    SELECT COUNT(*)
    INTO   v_check_count
    FROM   cks_wms_msn_seq
    WHERE  ORGANIZATION_ID = p_org_id
    AND    SERIAL_PREFIX = v_serial_prefix
    AND    SERIAL_DATE_CODE = v_date_str;

    IF  v_check_count = 0 THEN
		INSERT INTO cks_wms_msn_seq
		( ORGANIZATION_ID
          , SERIAL_PREFIX  
		  , SERIAL_DATE_CODE
		  , SERIAL_SEQ_NO 
		) VALUES (
		  p_org_id
          , v_serial_prefix
		  , v_date_str
		  , 1 );        
    ELSE    
		UPDATE cks_wms_msn_seq
           SET SERIAL_SEQ_NO = SERIAL_SEQ_NO + 1 
		 WHERE  ORGANIZATION_ID = p_org_id
         AND    SERIAL_PREFIX = v_serial_prefix
         AND    SERIAL_DATE_CODE = v_date_str;
    END IF;
    
    SELECT SERIAL_SEQ_NO
    INTO   v_serial_seq
    FROM   cks_wms_msn_seq
    WHERE  ORGANIZATION_ID = p_org_id
    AND    SERIAL_PREFIX = v_serial_prefix
    AND    SERIAL_DATE_CODE = v_date_str;

	SET v_serial_no = CONCAT(v_serial_prefix, p_org_id, v_date_str, 10000+v_serial_seq ); 

    INSERT INTO cks_wms_msn( 
	  SERIAL_NUMBER
     ,INVENTORY_ITEM_ID 
     ,CURRENT_ORGANIZATION_ID  
     ,CURRENT_SUBINVENTORY_CODE 
     ,CURRENT_LOCATOR_ID      
     ,CURRENT_STATUS    
     ,CREATION_DATE
     ,CREATED_BY 
     ,LAST_UPDATE_DATE
     ,LAST_UPDATED_BY)
	VALUES
	  ( v_serial_no
       ,v_item_id
	   ,p_org_id
       ,NULL
       ,NULL
	   ,1 -- Defined but not used
	   ,SYSDATE()
	   ,p_user_id
	   ,SYSDATE()
	   ,p_user_id
	  );
  
END IF;

IF v_returnCode = 'S' THEN
    SET x_serial_no = v_serial_no;
    SET x_returnCode = 'S';
	SET x_returnMsg = v_returnMsg; 
    COMMIT;
ELSE
    SET x_returnCode = 'E';
	SET x_returnMsg = CONCAT('Error-',v_process,'-',v_returnMsg);
    ROLLBACK;
END IF;

END