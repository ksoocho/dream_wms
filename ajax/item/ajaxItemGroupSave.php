<?php
include("../db.php");

// Check Parameter
if(isSet($_POST['org_id']) 
	&& isSet($_POST['item_group1'])
	&& isSet($_POST['item_group2'])
	&& isSet($_POST['item_group3'])
	&& isSet($_POST['item_group4'])
	&& isSet($_POST['item_group_descr'])
	&& isSet($_POST['user_id']))
{
	// username and password sent from Form
	$org_id      = mysqli_real_escape_string($db,$_POST['org_id']); 
	$item_group1 = mysqli_real_escape_string($db,$_POST['item_group1']); 
	$item_group2 = mysqli_real_escape_string($db,$_POST['item_group2']); 
	$item_group3 = mysqli_real_escape_string($db,$_POST['item_group3']); 
	$item_group4 = mysqli_real_escape_string($db,$_POST['item_group4']); 
	$item_group_descr = mysqli_real_escape_string($db,$_POST['item_group_descr']); 
	$user_id     = mysqli_real_escape_string($db,$_POST['user_id']); 

	// Prepare IN parameters
	$db->query("SET @p_org_id        = " . $org_id );
	$db->query("SET @p_item_group1   = " . "'" . $item_group1 . "'");
	$db->query("SET @p_item_group2   = " . "'" . $item_group2 . "'");
	$db->query("SET @p_item_group3   = " . "'" . $item_group3 . "'");
	$db->query("SET @p_item_group4   = " . "'" . $item_group4 . "'");
	$db->query("SET @p_item_group_descr   = " . "'" . $item_group_descr . "'");
	$db->query("SET @p_user_id       = " . $user_id );

	// Prepare OUT parameters
	$db->query("set @x_item_group_id = 0");
	$db->query("set @x_returnCode = '0'");
	$db->query("set @x_returnMsg = '0'");

	// Call sproc 
	if(!$db->query("call pr_wms_item_group(@p_org_id, 
	                                       @p_item_group1, 
	                                       @p_item_group2, 
	                                       @p_item_group3, 
	                                       @p_item_group4, 
	                                       @p_item_group_descr, 
	                                       @p_user_id, 
										   @x_item_group_id, 
										   @x_returnCode, 
										   @x_returnMsg)"))
	die("CALL failed: (" . $db->errno . ") " . $db->error);

	// Fetch OUT parameters 
	if (!($res = $db->query("select @x_item_group_id as item_group_id , 
									@x_returnCode as return_code, 
									@x_returnMsg as return_msg")))
		die("Fetch failed: (" . $db->errno . ") " . $db->error);
	
	$row = $res->fetch_assoc();

	//create user array
	$resultInfo[] = array(
	  'item_group_id' => $row['item_group_id'],
	  'return_code'   => $row['return_code'],
	  'return_msg'    => $row['return_msg']
	);
	
	echo json_encode($resultInfo);

	//close the db connection
	mysqli_close($db);	
}
?>