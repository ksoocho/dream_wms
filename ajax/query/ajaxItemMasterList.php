<?php

include("../db.php");

if(isSet($_POST['org_id'])
   && isSet($_POST['item_group1'])	
   && isSet($_POST['item_group2'])	
  )
{	
	$org_id      = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_group1 = mysqli_real_escape_string($db,$_POST['item_group1']); 
	$item_group2 = mysqli_real_escape_string($db,$_POST['item_group2']); 
	
	$sql =  "SELECT msib.INVENTORY_ITEM_ID              AS item_id
				  ,msib.SEGMENT1                        AS item_code
				  ,msib.ITEM_TYPE                       AS item_type
				  ,IFNULL(msib.ITEM_DESCRIPTION,' ')    AS item_descr
				  ,IFNULL(msib.ITEM_SPEC,' ')           AS item_spec
				  ,IFNULL(micg.CATALOG_DESCRIPTION,' ') AS item_group_descr
				  ,case msib.SERIAL_NUMBER_CONTROL_CODE when '1' then 'No' when '5' then 'Yes' else ' ' end  AS serial_flag
			FROM cks_wms_micg micg
				,cks_wms_item msib 
			WHERE micg.SEGMENT1 = '$item_group1'
			AND   micg.SEGMENT2 = '$item_group2'
			AND   msib.ORGANIZATION_ID = $org_id 
			AND   msib.ITEM_CATALOG_GROUP_ID = micg.ITEM_CATALOG_GROUP_ID
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{

		$item_id          = $row['item_id'];
		$item_code        = $row['item_code'];
		$item_type        = $row['item_type'];
		$item_descr       = $row['item_descr'];
		$item_spec        = $row['item_spec'];
		$item_group_descr = $row['item_group_descr'];
		$serial_flag      = $row['serial_flag'];

        $resultArray[] = array(
		  'item_id'      => $item_id,
		  'item_code'    => $item_code,
		  'item_type'    => $item_type,
		  'item_descr'   => $item_descr,
		  'item_spec'    => $item_spec,
		  'item_group_descr'   => $item_group_descr ,
		  'serial_flag'  => $serial_flag
		);
	}
	echo json_encode($resultArray);

	//close the db connection
	mysqli_close($db);
}	
?>