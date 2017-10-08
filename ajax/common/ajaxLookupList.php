<?php

include("../db.php");

if(isSet($_POST['lookup_type']))
{	
	$lookup_type = mysqli_real_escape_string($db,$_POST['lookup_type']); 
	
	$sql =  "SELECT LOOKUP_CODE AS lookup_code
				  ,LOOKUP_MEANING AS lookup_name
			FROM cks_wms_lookup
			WHERE LOOKUP_TYPE = '$lookup_type'
			AND   ENABLED_FLAG = 'Y'
			AND   START_DATE_ACTIVE <= SYSDATE()
			AND   IFNULL(END_DATE_ACTIVE,SYSDATE()) >= SYSDATE()
			" ;		
		
	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$lookupArray[] = array(
		  'lookup_code'  => $row['lookup_code'],
		  'lookup_name'  => $row['lookup_name']
		);
	}
	echo json_encode($lookupArray);

	//close the db connection
	mysqli_close($db);
}	
?>