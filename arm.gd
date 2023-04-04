@tool
extends Node3D

var skel
var starting_offsets = [Vector3(0, 4.43, 0), Vector3(0, 5.3, 0), Vector3(0, 1.5, 0)]
@export var IK_bone = "Finger"
var SamplingDistance = 0.01
var LearningRate = 0.05
var angles = []
var num_bones
@onready var target = get_parent().get_node("MeshInstance3D").global_transform.origin
# Called when the node enters the scene tree for the first time.
func _ready():
	skel = get_node("Armature/Skeleton3D")
	num_bones = skel.get_bone_count() - 1
	var b = 0
	while b < num_bones:
		angles.append(skel.get_bone_pose_rotation(b).get_angle())
		b += 1
	print_debug(angles)
	
	
func ForwardKinematics(angles):
	var b = 0
	var prev_point = skel.get_bone_global_pose(b).origin
	while b < num_bones:
		var rot = Quaternion(Vector3.BACK, angles[b])
		var next_point = prev_point + rot * starting_offsets[b]
		prev_point = next_point
		b += 1
		
	return prev_point
	
func DistanceFromTarget(target, angles):
	var point = ForwardKinematics(angles)
	return (point - target).length()
	
func PartialGradient(target, angles, i):
	var angle = angles[i]
	
	var f_x = DistanceFromTarget(target, angles)
	angles[i] += SamplingDistance
	var f_x_plus_d = DistanceFromTarget(target, angles)
	var gradient = (f_x_plus_d - f_x) / SamplingDistance
	
	angles[i] = angle
	
	return gradient
	
func InverseKinematics(target, angles):
	var b = 0
	while b < num_bones:
		var gradient = PartialGradient(target, angles, b)
		angles[b] -= LearningRate * gradient
		b += 1
		
	return angles
		
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Get bone from bottom of chain
	var b = 0
	target = get_parent().get_node("MeshInstance3D").global_transform.origin
	angles = InverseKinematics(target, angles)
#	print_debug(DistanceFromTarget(target, angles))
#	print_debug(ForwardKinematics(angles))
	var to_display = []
	for i in range(len(angles)):
		to_display.append(180 * angles[i] / PI)
	print_debug(to_display)
	
	# Each bone has an ID that increments down the chain
	var last_angle = 0
	while b < num_bones:
		var new_angle = angles[b] - last_angle
		var new_b_rot = Quaternion(Vector3.BACK, new_angle)
		skel.set_bone_pose_rotation(b, new_b_rot)
#		if b == 0:
#			print_debug(ForwardKinematics(angles), skel.get_bone_global_pose(2).origin)
			
#		print_debug(b, skel.get_bone_name(b))
		last_angle = new_angle
		b += 1

