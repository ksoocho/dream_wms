<?php
include("../db.php");

// Check Parameter
if(isSet($_POST['lookup_type']) 
	&& isSet($_POST['lookup_code'])
	&& isSet($_POST['lookup_meaning'])
	&& isSet($_POST['user_id']))
{
	// parameter sent from Form
	$lookup_type    = mysqli_real_escape_string($db,$_POST['lookup_type']); 
	$lookup_code    = mysqli_real_escape_string($db,$_POST['lookup_code']); 
	$lookup_meaning = mysqli_real_escape_string($db,$_POST['lookup_meaning']); 
	$lookup_descr   = mysqli_real_escape_string($db,$_POST['lookup_descr']); 
	$parent_type    = mysqli_real_escape_string($db,$_POST['parent_type']); 
	$parent_code    = mysqli_real_escape_string($db,$_POST['parent_code']); 
	$user_id        = mysqli_real_escape_string($db,$_POST['user_id']); 

	// Prepare IN parameters
	$db->query("SET @p_lookup_type    = " . "'" . $lookup_type . "'");
	$db->query("SET @p_lookup_code    = " . "'" . $lookup_code . "'");
	$db->query("SET @p_lookup_meaning = " . "'" . $lookup_meaning . "'");
	$db->query("SET @p_lookup_descr   = " . "'" . $lookup_descr . "'");
	$db->query("SET @p_parent_type    = " . "'" . $parent_type . "'");
	$db->query("SET @p_parent_code    = " . "'" . $parent_code . "'");
	$db->query("SET @p_user_id        = " . $user_id );

	// Prepare OUT parameters
	$db->query("set @x_returnCode = '0'");
	$db->query("set @x_returnMsg = '0'");

	// Call sproc 
	if(!$db->query("call pr_wms_lookup_save(@p_lookup_type, 
	                                       @p_lookup_code, 
	                                       @p_lookup_meaning, 
	                                       @p_lookup_descr, 
	                                       @p_parent_type, 
	                                       @p_parent_code, 
	                                       @p_user_id, 
										   @x_returnCode, 
										   @x_returnMsg)"))
	die("CALL failed: (" . $db->errno . ") " . $db->error);

	// Fetch OUT parameters 
	if (!($res = $db->query("select @x_returnCode as return_code, 
									@x_returnMsg as return_msg")))
		die("Fetch failed: (" . $db->errno . ") " . $db->error);
	
	$row = $res->fetch_assoc();

	//create user array
	$resultInfo[] = array(
	  'return_code'   => $row['return_code'],
	  'return_msg'    => $row['return_msg']
	);
	
	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);	
}
?>