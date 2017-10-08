<?php

include("../db.php");

if(isSet($_POST['resp_id']))
{	
	$resp_id = mysqli_real_escape_string($db,$_POST['resp_id']); 
	
	$sql =  "SELECT msi.SECONDARY_INVENTORY_NAME AS subinv_code
				   ,msi.SUBINV_DESCRIPTION AS subinv_name
			FROM cks_wms_resp resp
				,cks_wms_subinv msi
			WHERE resp.RESPONSIBILITY_ID = $resp_id
			AND   msi. ORGANIZATION_ID = resp.ORGANIZATION_ID
			AND   msi.EX_SUBINV_TYPE = resp.EX_SUBINV_TYPE 
			" ;

	//echo $sql;

	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$subinvArray[] = array(
		  'subinv_code'  => $row['subinv_code'],
		  'subinv_name'  => $row['subinv_name']
		);
	}
	echo json_encode($subinvArray);

	//close the db connection
	mysqli_close($db);
}	
?>