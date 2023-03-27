extends Node3D

var skel
var starting_offsets = [Vector3(0, 4.43, 0), Vector3(0, 5.3, 0), Vector3(0, 1.0, 0)]
@export var IK_bone = "Finger"
var SamplingDistance = 0.01
var LearningRate = 0.001
var angles = []
@onready var target = get_parent().get_node("MeshInstance3D").global_transform.origin
# Called when the node enters the scene tree for the first time.
func _ready():
	skel = get_node("Armature/Skeleton3D")
	
	var b = 0
	while b < skel.get_bone_count():
		angles.append(skel.get_bone_pose_rotation(b).get_angle())
		b += 1
	
	
func ForwardKinematics(angles):
	var b = 0
	var prev_point = skel.get_bone_pose_position(b)
	while b < skel.get_bone_count():
		var rot = Quaternion(Vector3(0,0,1), angles[b])
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
	while b < skel.get_bone_count():
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
	
	# Each bone has an ID that increments down the chain
	while b < skel.get_bone_count():
		var new_b_rot = Quaternion(Vector3.BACK, angles[b])
		skel.set_bone_pose_rotation(b, new_b_rot)
		b += 1

