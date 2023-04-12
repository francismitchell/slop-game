@tool
extends Node3D

var skel
var starting_offsets = [Vector3(0, 1.0, 0), Vector3(0, 4.43, 0), Vector3(0, 5.3, 0), Vector3(0, 1.5, 0)]
var SamplingDistance = 0.05
var LearningRate = 0.01
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
	
	
func ForwardKinematics(angles):
	var b = 0
	var axes = [Vector3.BACK, Vector3.RIGHT, Vector3.BACK, Vector3.BACK]
	var prev_point = skel.get_bone_pose(b).origin
	while b < num_bones:
		var rot = Quaternion(axes[b], angles[b])
		var next_point = prev_point + rot * starting_offsets[b]
		if b == 0:
			print(next_point)
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
	var last_angle = 0
	#var min_angles = [0.1, 0.1, 0.01]
	#var max_angles = [PI, PI/1.1, 0.4]
	#var min_angles = [0.1, -99.9, 0.01]
	#var max_angles = [PI, 99.9, 0.4]
	while b < num_bones:
		var gradient = PartialGradient(target, angles, b)
		angles[b] -= LearningRate * gradient
		#angles[b] = clamp(angles[b], last_angle + min_angles[b], last_angle + max_angles[b])
		last_angle = angles[b]
		b += 1
		
	return angles
		
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
var i = 0
func _process(delta):
	# find target
	target = get_parent().get_node("MeshInstance3D").global_transform.origin
	
	# Get bone from bottom of chain
	var b = 0
	var axes = [Vector3.BACK, Vector3.RIGHT, Vector3.BACK, Vector3.BACK]

	get_parent().get_node("Mesh2").global_transform.origin = ForwardKinematics(angles)
	if DistanceFromTarget(target, angles) > 0.001:
		angles = InverseKinematics(target, angles)

		
		# Each bone has an ID that increments down the chain
		var last_angle = 0
		# initialise dictionary
		var last_angles = {}
		for ax in axes:
			last_angles[ax] = 0
		while b < num_bones:

			var new_angle = angles[b] - last_angles[axes[b]]
			var new_b_rot = Quaternion(axes[b], new_angle)
			skel.set_bone_pose_rotation(b, new_b_rot)
			last_angles[axes[b]] += new_angle
			b += 1
	i += 1


