using Godot;
using System;

public partial class cau_lua : Area2D
{
	[Export]
	private float speed = 400f;
	private float max_range = 200f;
	private Vector2 direction = Vector2.Right;
	private float distance_traveled = 0f;
	public override void _Ready()
	{
		GetNode<AnimatedSprite2D>("AnimatedSprite2D").Play("Skill");
	}

	public void Initialize(Vector2 dir) // Nên viết hoa tên hàm theo chuẩn C#
	{
		direction = dir;
		Rotation = direction.Angle();
	}
	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _PhysicsProcess(double delta)
	{
		// Ép kiểu delta từ double sang float để tính toán nhân với speed
		float move_distance = speed * (float)delta;
		GlobalPosition += direction * move_distance;

		distance_traveled += move_distance;

		if (distance_traveled >= max_range)
		{
			QueueFree();
		}
	}
}
