using Godot;
using System;

public partial class cau_lua : Area2D
{
	[Export]
	private float speed = 400f;
	private float max_range = 200f;
	private Vector2 direction = Vector2.Right;
	private float distance_traveled = 0f;

	[Export] private float damage = 25f;
	public override void _Ready()
	{
		GetNode<AnimatedSprite2D>("AnimatedSprite2D").Play("Skill");
		// Kết nối signal AreaEntered để bắt sự kiện va chạm với Hurtbox của enemy
		AreaEntered += OnAreaEntered;
	}

	public void Initialize(Vector2 dir) // Nên viết hoa tên hàm theo chuẩn C#
	{
		direction = dir;
		Rotation = direction.Angle();
	}
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
	private void OnAreaEntered(Area2D area)
	{
		// Kiểm tra xem thứ mà skill chạm vào có phải là Hurtbox không 
		// (Dựa vào tên node hoặc Group "Hurtbox" mà bạn đặt cho node Hurtbox của Enemy)
		if (area.Name == "Hurtbox" || area.IsInGroup("Hurtbox"))
		{
			// Lấy ra node cha của Hurtbox (chính là EnemyBase chứa hàm TakeDamage)
			// Cấu trúc của bạn: EnemyBase -> Hurtbox (Area2D), nên EnemyBase là Owner hoặc GetParent()
			var enemy = area.GetParent();

			if (enemy.HasMethod("TakeDamage"))
			{
				enemy.Call("TakeDamage", damage); // Gọi hàm TakeDamage bên Enemy
			}

			// Va chạm xong thì hủy skill cầu lửa đi
			QueueFree();
		}
	}
}
