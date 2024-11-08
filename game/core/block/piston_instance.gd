class_name PistonInstance
extends BlockInstance

enum State { IDLE, MOVE }

@export var num_segments: int= 5

@onready var segments_node: Node3D = $Segments
@onready var orig_segment: MeshInstance3D = $Segments/Segment

@onready var joint: Generic6DOFJoint3D = $Generic6DOFJoint3D

var piston_head: Node3D
var sub_grid: BlockGrid

var state: State= State.MOVE
var segments: Array[Node3D]
var extension: float= 0
var velocity: float= 1.0

var max_distance: float



func _ready() -> void:
	for i in num_segments - 1:
		var next_segment: MeshInstance3D= orig_segment.duplicate()
		segments_node.add_child(next_segment)
		next_segment.mesh= next_segment.mesh.duplicate()
		var mesh: CylinderMesh= next_segment.mesh
		mesh.bottom_radius= mesh.bottom_radius - (i + 1) / 50.0
		mesh.top_radius= mesh.bottom_radius
	
	segments.assign(segments_node.get_children())

	max_distance= segments.size()
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, max_distance)


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	sub_grid= BlockGrid.new()
	sub_grid.position= grid.get_global_block_pos(grid_block.local_pos) + global_basis.y
	sub_grid.rotation= grid.rotation
	
	Global.game.grids.add_child(sub_grid)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)
	
	var piston_head_block: Block= load("res://game/data/blocks/piston head/piston_head_block.tres")
	piston_head= sub_grid.add_block(piston_head_block, Vector3i.ZERO, grid_block.rotation)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	var extension: float= global_position.distance_to(piston_head.global_position) - 1
	DebugHud.send("Extension", extension)
	
	for i in segments.size():
		segments[i].position.y= lerp(0.0, float(i + 1), extension / max_distance)

	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, velocity)
