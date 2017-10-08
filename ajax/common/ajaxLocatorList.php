<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['subinv_code'])	
  )
{	
	$org_id = mysqli_real_escape_string($db,$_POST['org_id']); 
	$subinv_code = mysqli_real_escape_string($db,$_POST['subinv_code']); 
	
	$sql =  "SELECT INVENTORY_LOCATION_ID AS locator_id
				   ,SEGMENT1              AS locator_code
				   ,LOCATOR_DESCRIPTION   AS locator_name
			FROM cks_wms_loc
			WHERE ORGANIZATION_ID = $org_id
			AND   SUBINVENTORY_CODE = '$subinv_code'
			AND   ENABLED_FLAG = 'Y'
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$resultArray[] = array(
		  'locator_id'    => $row['locator_id'],
		  'locator_code'  => $row['locator_code'],
		  'locator_name'  => $row['locator_name']
		);
	}
	echo json_encode($resultArray);

	//close the db connection
	mysqli_close($db);
}	
?>