<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['subinv_code'])	
   && isSet($_POST['loc_code']))
{	

	$org_id = mysqli_real_escape_string($db,$_POST['org_id']); 
	$subinv_code = mysqli_real_escape_string($db,$_POST['subinv_code']); 
	$loc_code = mysqli_real_escape_string($db,$_POST['loc_code']); 

    $v_locator_id = 0;
	
	$sql =  "SELECT INVENTORY_LOCATION_ID AS locator_id
			FROM cks_wms_loc
			WHERE ORGANIZATION_ID = $org_id
			AND   SUBINVENTORY_CODE = '$subinv_code'
			AND   SEGMENT1  =  '$loc_code'
			AND   ENABLED_FLAG = 'Y'
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
	   $v_locator_id = $row['locator_id'];
	}
	
	$resultInfo[] = array(
	  'locator_id'    => $v_locator_id
	);
	
	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);
}	
?>