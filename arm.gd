extends Node3D

var skel
@export var IK_bone = "Finger"
# Called when the node enters the scene tree for the first time.
func _ready():
	skel = get_node("Armature/Skeleton3D")
	var b = skel.find_bone(IK_bone)
	while b >= 0:
		print(b)
		print("name: ", skel.get_bone_name(b))
		print("local transform: ", skel.get_bone_pose(b))
		print( "global transform:", skel.get_bone_global_pose(b))
		var b_rot = skel.get_bone_pose_rotation(b)
		var new_b_rot = Quaternion(Vector3.BACK, 0.01) * b_rot
		skel.set_bone_pose_rotation(b, new_b_rot)
		b = skel.get_bone_parent(b)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var b = skel.find_bone(IK_bone)
	while b >= 0:
		var b_rot = skel.get_bone_pose_rotation(b)
		var new_b_rot = Quaternion(Vector3.BACK, 0.01) * b_rot
		skel.set_bone_pose_rotation(b, new_b_rot)
		b = skel.get_bone_parent(b)
