<?php

include("../db.php");

if(isSet($_POST['resp_id']))
{	
	$resp_id = mysqli_real_escape_string($db,$_POST['resp_id']); 
	
	$sql =  "SELECT resp.RESPONSIBILITY_NAME AS resp_name
				  ,resp.ORGANIZATION_ID  AS org_id
				  ,resp.EX_SUBINV_TYPE   AS subinv_type
				  ,resp.EX_SUBINV_DETAIL AS subinv_detail
			FROM cks_wms_resp resp
			WHERE resp.RESPONSIBILITY_ID = $resp_id
			" ;

	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$respInfo[] = array(
		  'resp_name'      => $row['resp_name'],
		  'org_id'         => $row['org_id'],
		  'subinv_type'    => $row['subinv_type'],
		  'subinv_detail'  => $row['subinv_detail']
		);
	}
	echo json_encode($respInfo);

	//close the db connection
	mysqli_close($db);
}	
?>