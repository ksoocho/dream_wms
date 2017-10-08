<?php
include("../db.php");

// Check Parameter
if(isSet($_GET['org_id']) 
	&& isSet($_GET['subinv_code'])
	&& isSet($_GET['locator_code'])
	&& isSet($_GET['lpn_code'])
	&& isSet($_GET['txn_type_id'])
	&& isSet($_GET['txn_reference'])
	&& isSet($_GET['user_id']))
{
	// username and password sent from Form
	$org_id        = mysqli_real_escape_string($db,$_GET['org_id']); 
	$subinv_code   = mysqli_real_escape_string($db,$_GET['subinv_code']); 
	$locator_code  = mysqli_real_escape_string($db,$_GET['locator_code']); 
	$lpn_code      = mysqli_real_escape_string($db,$_GET['lpn_code']); 
	$txn_type_id   = mysqli_real_escape_string($db,$_GET['txn_type_id']); 
	$txn_reference = mysqli_real_escape_string($db,$_GET['txn_reference']); 
	$user_id       = mysqli_real_escape_string($db,$_GET['user_id']); 

	// Prepare IN parameters
	$db->query("SET @p_org_id        = " . $org_id );
	$db->query("SET @p_subinv_code   = " . "'" . $subinv_code . "'");
	$db->query("SET @p_locator_code  = " . "'" . $locator_code . "'");
	$db->query("SET @p_lpn_code      = " . "'" . $lpn_code . "'");
	$db->query("SET @p_txn_type_id   = " . $txn_type_id );
	$db->query("SET @p_txn_reference = " . "'" . $txn_reference . "'");
	$db->query("SET @p_user_id       = " . $user_id );

	// Prepare OUT parameters
	$db->query("set @x_returnCode = '0'");
	$db->query("set @x_returnMsg = '0'");

	// Call sproc 
	if(!$db->query("call pr_wms_txn_issue_lpn(@p_org_id, 
	                                      @p_subinv_code, 
	                                      @p_locator_code, 
	                                      @p_lpn_code, 
	                                      @p_txn_type_id, 
										  @p_txn_reference, 
										  @p_user_id, 
										  @x_returnCode, 
										  @x_returnMsg)"))
	die("CALL failed: (" . $db->errno . ") " . $db->error);

	// Fetch OUT parameters 
	$res = $db->query("select @x_returnCode as return_code,	@x_returnMsg as return_msg"); 

	if($res->num_rows > 0) 
	{
		while($row = mysqli_fetch_array($res, MYSQLI_ASSOC))
		{
			$return_code = $row['return_code'];
			$return_msg = $row['return_msg'];
		}
	}
	else {
		$return_code = 'E';
		$return_msg = 'No Data Found';
	}
		
	//create user array
	$resultInfo[] = array(
	  'return_code'   => $return_code,
	  'return_msg'    => $return_msg
	);
	
	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);	
}
?>