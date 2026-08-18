using Godot;
using System;

public partial class BaseSkillTamXa : Base
{
	protected virtual float speed { get; set; } = 400f;
	protected virtual float max_range { get; set; } = 200f;

	public override float Stamina { get; set; } = 10f;
	public override float Damage { get; set; } = 25f;
	public override float Cooldown { get; set; } = 1.0f;

	private float distance_traveled = 0f;

	public override void _PhysicsProcess(double delta)
	{
		float move_distance = speed * (float)delta;
		GlobalPosition += direction * move_distance;

		distance_traveled += move_distance;

		if (distance_traveled >= max_range)
		{
			QueueFree();
		}
	}
}
