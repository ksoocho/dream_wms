<?php

include("../db.php");

if(isSet($_POST['lookup_type']))
{	
	$lookup_type = mysqli_real_escape_string($db,$_POST['lookup_type']); 
	$lookup_code = mysqli_real_escape_string($db,$_POST['lookup_code']); 
	
	$sql =  "SELECT LOOKUP_MEANING      AS lookup_name
	               ,LOOKUP_DESCRIPTION  AS lookup_descr
	               ,PARENT_LOOKUP_TYPE  AS parent_lookup_type 
                   ,PARENT_LOOKUP_CODE  AS parent_lookup_code  
			FROM cks_wms_lookup
			WHERE LOOKUP_TYPE = '$lookup_type'
			AND   LOOKUP_CODE = '$lookup_code'
			AND   ENABLED_FLAG = 'Y'
			AND   START_DATE_ACTIVE <= SYSDATE()
			AND   IFNULL(END_DATE_ACTIVE,SYSDATE()) >= SYSDATE()
			" ;		

	$result = mysqli_query($db, $sql) or die("Error in Selecting " . mysqli_error($db));

	while($row =mysqli_fetch_assoc($result))
	{
		$v_lookup_name  = $row['lookup_name'];
		$v_lookup_descr = $row['lookup_descr'];
		$v_parent_lookup_type = $row['parent_lookup_type'];
		$v_parent_lookup_code = $row['parent_lookup_code'];
	}

	if ( $v_parent_lookup_code != null)
	{
		
        $sql2 =  "SELECT LOOKUP_MEANING      AS parent_lookup_name
					   ,LOOKUP_DESCRIPTION   AS parent_lookup_descr
				FROM cks_wms_lookup
				WHERE LOOKUP_TYPE = 'LOOKUP_TYPE'
				AND   LOOKUP_CODE = '$v_parent_lookup_code'
				AND   ENABLED_FLAG = 'Y'
				AND   START_DATE_ACTIVE <= SYSDATE()
				AND   IFNULL(END_DATE_ACTIVE,SYSDATE()) >= SYSDATE()
				" ;		

		$result2 = mysqli_query($db, $sql2) or die("Error in Selecting " . mysqli_error($db));

		while($row2 =mysqli_fetch_assoc($result2))
		{
			$v_parent_lookup_name  = $row2['parent_lookup_name'];
			$v_parent_lookup_descr = $row2['parent_descr'];
		}			
	}
	
	$resultInfo[] = array(
	  'lookup_name'         => $v_lookup_name,
	  'lookup_descr'        => $v_lookup_descr,
	  'parent_lookup_type'  => $v_parent_lookup_type,
	  'parent_lookup_code'  => $v_parent_lookup_code,
	  'parent_lookup_name'  => $v_parent_lookup_name,
	  'parent_lookup_descr' => $v_parent_lookup_descr
	);

	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);
}	
?>