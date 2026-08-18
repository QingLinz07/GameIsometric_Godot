using Godot;
using System;

public partial class CauLua : Base
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		speed = 400f;
		max_range = 200f;
		damage = 25f;
		base._Ready();
	}

}
