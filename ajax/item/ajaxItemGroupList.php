<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['group_type'])	
   && isSet($_POST['group_code']))
{	
	$org_id     = mysqli_real_escape_string($db,$_POST['org_id']); 
	$group_type = mysqli_real_escape_string($db,$_POST['group_type']); 
	$group_code = mysqli_real_escape_string($db,$_POST['group_code']); 
	
	// 대분류
	if ( $group_type == 'L')
	{
		$sql =  "SELECT LOOKUP_CODE AS item_group_code
					  ,LOOKUP_MEANING AS item_group_name
				FROM cks_wms_org_lookup
				WHERE LOOKUP_TYPE = 'ITEM_GROUP_01'
				AND   ENABLED_FLAG = 'Y'
				AND   START_DATE_ACTIVE <= SYSDATE()
				AND   IFNULL(END_DATE_ACTIVE,SYSDATE()) >= SYSDATE()
				AND   MASTER_ORGANIZATION_ID = $org_id
				" ;
		
	} else if ( $group_type == 'M' ) 
    {

		$sql =  "SELECT LOOKUP_CODE AS item_group_code
					  ,LOOKUP_MEANING AS item_group_name
				FROM cks_wms_org_lookup fl
				WHERE LOOKUP_TYPE = 'ITEM_GROUP_02'
				AND   ENABLED_FLAG = 'Y'
				AND   START_DATE_ACTIVE <= SYSDATE()
				AND   IFNULL(END_DATE_ACTIVE,SYSDATE()) >= SYSDATE()
				AND   PARENT_LOOKUP_TYPE = 'ITEM_GROUP_01'
				AND   PARENT_LOOKUP_CODE = '$group_code'
				AND   MASTER_ORGANIZATION_ID = $org_id
				" ;

	} else if ( $group_type == 'S' ) 
    {

		$sql =  "SELECT LOOKUP_CODE AS item_group_code
					  ,LOOKUP_MEANING  AS item_group_name
				FROM cks_wms_org_lookup fl
				WHERE LOOKUP_TYPE = 'ITEM_GROUP_03'
				AND   ENABLED_FLAG = 'Y'
				AND   START_DATE_ACTIVE <= SYSDATE()
				AND   IFNULL(END_DATE_ACTIVE,SYSDATE()) >= SYSDATE()
				AND   PARENT_LOOKUP_TYPE = 'ITEM_GROUP_02'
				AND   PARENT_LOOKUP_CODE = '$group_code'
				AND   MASTER_ORGANIZATION_ID = $org_id
				" ;

	}	
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$itemgroupArray[] = array(
		  'item_group_code'  => $row['item_group_code'],
		  'item_group_name'  => $row['item_group_name']
		);
	}
	echo json_encode($itemgroupArray);

	//close the db connection
	mysqli_close($db);
}	
?>