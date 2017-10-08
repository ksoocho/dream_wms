<?php
include("../db.php");

// Check Parameter
if(isSet($_POST['org_id']) 
	&& isSet($_POST['subinv_code'])
	&& isSet($_POST['locator_code'])
	&& isSet($_POST['item_code'])
	&& isSet($_POST['txn_qty'])
	&& isSet($_POST['txn_type_id'])
	&& isSet($_POST['txn_reference'])
	&& isSet($_POST['user_id']))
{
	// username and password sent from Form
	$org_id        = mysqli_real_escape_string($db,$_POST['org_id']); 
	$subinv_code   = mysqli_real_escape_string($db,$_POST['subinv_code']); 
	$locator_code  = mysqli_real_escape_string($db,$_POST['locator_code']); 
	$item_code     = mysqli_real_escape_string($db,$_POST['item_code']); 
	$txn_qty       = mysqli_real_escape_string($db,$_POST['txn_qty']); 
	$serial_no     = mysqli_real_escape_string($db,$_POST['serial_no']); 
	$txn_type_id   = mysqli_real_escape_string($db,$_POST['txn_type_id']); 
	$txn_reference = mysqli_real_escape_string($db,$_POST['txn_reference']); 
	$user_id       = mysqli_real_escape_string($db,$_POST['user_id']); 

	// Prepare IN parameters
	$db->query("SET @p_org_id        = " . $org_id );
	$db->query("SET @p_subinv_code   = " . "'" . $subinv_code . "'");
	$db->query("SET @p_locator_code  = " . "'" . $locator_code . "'");
	$db->query("SET @p_item_code     = " . "'" . $item_code . "'");
	$db->query("SET @p_txn_qty       = " . $txn_qty );
	$db->query("SET @p_serial_no     = " . "'" . $serial_no . "'");
	$db->query("SET @p_txn_type_id   = " . $txn_type_id );
	$db->query("SET @p_txn_reference = " . "'" . $txn_reference . "'");
	$db->query("SET @p_user_id       = " . $user_id );

	// Prepare OUT parameters
	$db->query("set @x_returnCode = '0'");
	$db->query("set @x_returnMsg = '0'");

	// Call sproc 
	if(!$db->query("call pr_wms_txn_receipt(@p_org_id, 
	                                          @p_subinv_code, 
	                                          @p_locator_code, 
	                                          @p_item_code, 
	                                          @p_txn_qty, 
	                                          @p_serial_no, 
	                                          @p_txn_type_id, 
										      @p_txn_reference, 
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