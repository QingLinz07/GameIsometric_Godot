using Godot;
using System;

public partial class Base : Area2D
{
	// Các chỉ số chung cho mọi skill
	public virtual float Stamina { get; set; } = 10f;
	public virtual float Damage { get; set; } = 25f;
	public virtual float Cooldown { get; set; } = 1.0f;

	protected Vector2 direction = Vector2.Right;

	public override void _Ready()
	{
		// Kiểm tra xem node có AnimatedSprite2D không trước khi gọi để tránh lỗi nếu skill khác không có
		if (HasNode("AnimatedSprite2D"))
		{
			GetNode<AnimatedSprite2D>("AnimatedSprite2D").Play("Skill");
		}
		AreaEntered += OnAreaEntered;
	}

	public virtual void Initialize(Vector2 dir)
	{
		direction = dir;
		Rotation = direction.Angle();
	}

	public virtual void OnAreaEntered(Area2D area)
	{
		if (area.Name == "Hurtbox" || area.IsInGroup("Hurtbox"))
		{
			var enemy = area.GetParent();

			if (enemy.HasMethod("TakeDamage"))
			{
				enemy.Call("TakeDamage", Damage);
			}
			QueueFree();
		}
	}
}