<?php

include("../db.php");

if(isSet($_POST['item_code']))
{	
	$org_id    = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_code = mysqli_real_escape_string($db,$_POST['item_code']); 
	
	$v_item_id = 0;
	
	$sql =  "SELECT msib.INVENTORY_ITEM_ID AS item_id
				   ,msib.ITEM_TYPE         AS item_type
				   ,msib.ITEM_DESCRIPTION  AS item_descr
				   ,msib.ITEM_SPEC         AS item_spec
				   ,msib.SERIAL_NUMBER_CONTROL_CODE AS serial_code
			FROM  cks_wms_item msib
			WHERE msib.ORGANIZATION_ID = $org_id
			AND   msib.SEGMENT1        = '$item_code'
			" ;

	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$v_item_id     = $row['item_id'];
		$v_item_type   = $row['item_type'];
		$v_item_descr  = $row['item_descr'];
		$v_item_spec   = $row['item_spec'];
		$v_serial_code = $row['serial_code'];
    }

	$resultInfo[] = array(
	  'item_id'      => $v_item_id,
	  'item_type'    => $v_item_type,
	  'item_descr'   => $v_item_descr,
	  'item_spec'    => $v_item_spec,
	  'serial_code'  => $v_serial_code
	);

	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);
}	
?>