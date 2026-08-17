using Godot;

public partial class Cao : Enemy
{
	public override void _Ready()
	{
		EnemyName = "Cáo Vàng";
		base._Ready();
	}

	protected override void OnAggroBodyEntered(Node2D body)
	{
		base.OnAggroBodyEntered(body);

		// Chỉ tăng tốc khi thực sự nhận diện được player và bắt đầu rượt đuổi
		if (body.IsInGroup("Player") && IsPointInsidePolygon(body.GlobalPosition))
		{
			MoveSpeed = 170f;
		}
	}

	protected override void OnAggroBodyExited(Node2D body)
	{
		base.OnAggroBodyExited(body);

		// Chỉ reset tốc độ khi đối tượng rời đi chính là mục tiêu (targetPlayer) bị mất dấu
		if (body == targetPlayer || (body.IsInGroup("Player") && targetPlayer == null))
		{
			MoveSpeed = 120f;
		}
	}
}
