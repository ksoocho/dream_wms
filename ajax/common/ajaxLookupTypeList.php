<?php

include("../db.php");

$sql =  "SELECT LOOKUP_CODE AS lookup_code
			  ,LOOKUP_MEANING AS lookup_name
		FROM cks_wms_lookup
		WHERE LOOKUP_TYPE = 'LOOKUP_TYPE'
		AND   ENABLED_FLAG = 'Y'
		AND   START_DATE_ACTIVE <= SYSDATE()
		AND   IFNULL(END_DATE_ACTIVE,SYSDATE()) >= SYSDATE()
		AND   LOOKUP_CODE NOT LIKE 'ITEM_GROUP%'
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
	
?>