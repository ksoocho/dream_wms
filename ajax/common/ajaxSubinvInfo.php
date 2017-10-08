<?php

include("../db.php");

if(isSet($_POST['subinv_code']))
{	
	$org_id      = mysqli_real_escape_string($db,$_POST['org_id']); 
	$subinv_code = mysqli_real_escape_string($db,$_POST['subinv_code']); 
	
	$sql =  "SELECT msi.EX_SUBINV_TYPE AS subinv_type
				   ,msi.EX_SUBINV_DETAIL AS subinv_detail
				   ,msi.SUBINV_DESCRIPTION AS subinv_descr
			FROM cks_wms_subinv msi
			WHERE msi.ORGANIZATION_ID = $org_id
			AND   msi.SECONDARY_INVENTORY_NAME = '$subinv_code'
			" ;

	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$subinvInfo[] = array(
		  'subinv_type'   => $row['subinv_type'],
		  'subinv_detail' => $row['subinv_detail'],
		  'subinv_descr'  => $row['subinv_descr']
		);
	}
	echo json_encode($subinvInfo);

	//close the db connection
	mysqli_close($db);
}	
?>