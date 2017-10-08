CREATE DEFINER=`root`@`localhost` PROCEDURE `pr_wms_item_group`(
      IN p_org_id            INT
 	, IN p_item_group1       VARCHAR(40)  
 	, IN p_item_group2       VARCHAR(40)  
 	, IN p_item_group3       VARCHAR(40)  
 	, IN p_item_group4       VARCHAR(40)  
    , IN p_user_id           INT
	, OUT x_item_group_id    INT  
	, OUT x_returnCode       VARCHAR(5)
 	, OUT x_returnMsg        VARCHAR(255)
)
BEGIN

-- **********************************************
-- Procedure Name : pr_wms_serial_generate
-- Description    : Serial Generate
-- 2016/03/06   ksoocho   최초 작성
-- **********************************************
DECLARE v_item_group_id INT;
DECLARE v_item_group4   VARCHAR(40);

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
    OR ( p_item_group1 IS NULL ) 
    OR ( p_item_group2 IS NULL ) 
    OR ( p_item_group3 IS NULL ) THEN

   SET v_returnCode = 'E';
   SET v_returnMsg = 'Invalid Parameter'; 

END IF;

-- Check Item Group 
IF v_returnCode = 'S' THEN

	SELECT COUNT(*)
	INTO  v_check_count
	FROM cks_wms_lookup
	WHERE LOOKUP_TYPE = 'ITEM_GROUP_01'
	AND   LOOKUP_CODE = p_item_group1;
    
    IF v_check_count = 0 THEN
	   SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Item Group 1'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

	SELECT COUNT(*)
	INTO  v_check_count
	FROM cks_wms_lookup
	WHERE LOOKUP_TYPE = 'ITEM_GROUP_02'
	AND   LOOKUP_CODE = p_item_group2
    AND   PARENT_LOOKUP_TYPE =  'ITEM_GROUP_01'
    AND   PARENT_LOOKUP_CODE = p_item_group1 ;
    
    IF v_check_count = 0 THEN
	   SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Item Group 2'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

	SELECT COUNT(*)
	INTO  v_check_count
	FROM cks_wms_lookup
	WHERE LOOKUP_TYPE = 'ITEM_GROUP_03'
	AND   LOOKUP_CODE = p_item_group3
    AND   PARENT_LOOKUP_TYPE =  'ITEM_GROUP_02'
    AND   PARENT_LOOKUP_CODE = p_item_group2 ;
    
    IF v_check_count = 0 THEN
	   SET v_returnCode = 'E';
	   SET v_returnMsg = 'Invalid Item Group 2'; 
    END IF;

END IF;

IF v_returnCode = 'S' THEN

   IF p_item_group4 IS NULL THEN
      SET v_item_group4 = 'COMMON';
   ELSE
      SET v_item_group4 = p_item_group4;
   END IF;   

END IF;

IF v_returnCode = 'S' THEN

   SELECT COUNT(*)
   INTO v_check_count
   FROM  cks_wms_micg
   WHERE SEGMENT1 = p_item_group1
   AND   SEGMENT2 = p_item_group2
   AND   SEGMENT3 = p_item_group3
   AND   SEGMENT4 = v_item_group4;
   
   IF v_check_count = 0 THEN
      INSERT INTO cks_wms_micg
		 ( SEGMENT1
		  ,SEGMENT2
		  ,SEGMENT3
		  ,SEGMENT4
		  ,CATALOG_DESCRIPTION
		  ,PARENT_CATALOG_GROUP_ID     
		  ,ENABLED_FLAG  
		  ,INACTIVE_DATE  
		  ,CREATION_DATE  
		  ,CREATED_BY 
		  ,LAST_UPDATE_DATE 
		  ,LAST_UPDATED_BY  ) 
       VALUES (
           p_item_group1
           ,p_item_group2
           ,p_item_group3
           ,v_item_group4
           ,CONCAT(p_item_group1,' ',p_item_group2,' ',p_item_group3)
           ,NULL
           ,'Y'
           ,NULL
           ,SYSDATE()
           ,p_user_id
           ,SYSDATE()
           ,p_user_id);
           
       SET v_item_group_id =  LAST_INSERT_ID();   
   ELSE
	   SELECT ITEM_CATALOG_GROUP_ID
	   INTO v_item_group_id
	   FROM  cks_wms_micg
	   WHERE SEGMENT1 = p_item_group1
	   AND   SEGMENT2 = p_item_group2
	   AND   SEGMENT3 = p_item_group3
       AND   SEGMENT4 = v_item_group4;
   END IF;

END IF;


IF v_returnCode = 'S' THEN
    SET x_item_group_id = v_item_group_id;
    SET x_returnCode = 'S';
	SET x_returnMsg = v_returnMsg; 
    COMMIT;
ELSE
    SET x_returnCode = 'E';
	SET x_returnMsg = CONCAT('Error-',v_process,'-',v_returnMsg);
    ROLLBACK;
END IF;

END