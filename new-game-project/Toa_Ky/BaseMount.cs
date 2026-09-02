using Godot;

public partial class BaseMount : Node2D
{
	[Export] public string MountId { get; set; } = "horse_default";
	[Export] public float SpeedBonus { get; set; } = 50.0f;
	[Export] public string MountAnimPrefix { get; set; } = "Ride";

	// Cấu hình Z-Index riêng cho từng hướng ngay trên Inspector
	[ExportGroup("Z-Index Configuration per Direction")]
	[Export] public int Z_Down { get; set; } = 2;
	[Export] public int Z_DownLeft { get; set; } = 2;
	[Export] public int Z_DownRight { get; set; } = 2;
	[Export] public int Z_Left { get; set; } = 2;
	[Export] public int Z_Right { get; set; } = 2;
	[Export] public int Z_Up { get; set; } = 1;
	[Export] public int Z_UpLeft { get; set; } = 1;
	[Export] public int Z_UpRight { get; set; } = 1;

	// Cấu hình tên Animation riêng cho Player theo từng hướng (Hỗ trợ cả Stand và Walk hoặc gộp tùy ý)
	[ExportGroup("Player Animation Configuration per Direction")]
	[Export] public string Anim_Down { get; set; } = "Ride_Down";
	[Export] public string Anim_DownLeft { get; set; } = "Ride_Down_Left";
	[Export] public string Anim_DownRight { get; set; } = "Ride_Down_Right";
	[Export] public string Anim_Left { get; set; } = "Ride_Left";
	[Export] public string Anim_Right { get; set; } = "Ride_Right";
	[Export] public string Anim_Up { get; set; } = "Ride_Up";
	[Export] public string Anim_UpLeft { get; set; } = "Ride_Up_Left";
	[Export] public string Anim_UpRight { get; set; } = "Ride_Up_Right";

	protected AnimatedSprite2D sprite;

	public override void _Ready()
	{
		sprite = GetNodeOrNull<AnimatedSprite2D>("AnimatedSprite2D");
	}

	public void PlayMountAnimation(string animType, string directionName)
	{
		if (sprite != null)
		{
			string animName = $"{MountAnimPrefix}_{animType}_{directionName}";
			if (!sprite.SpriteFrames.HasAnimation(animName))
			{
				animName = $"{animType}_{directionName}";
			}

			if (sprite.SpriteFrames.HasAnimation(animName) && sprite.Animation != animName)
			{
				sprite.Play(animName);
			}
		}
	}

	// Lấy Z-Index cấu hình theo tên hướng
	public int GetZIndexForDirection(string dirName)
	{
		return dirName switch
		{
			"Down" => Z_Down,
			"Down_Left" => Z_DownLeft,
			"Down_Right" => Z_DownRight,
			"Left" => Z_Left,
			"Right" => Z_Right,
			"Up" => Z_Up,
			"Up_Left" => Z_UpLeft,
			"Up_Right" => Z_UpRight,
			_ => 1
		};
	}

	// Lấy tên Animation tùy chỉnh cho Player theo hướng
	public string GetCustomPlayerAnimation(string dirName, string animType)
	{
		// Bạn có thể tự định nghĩa cách map chuỗi, ví dụ ưu tiên lấy chuỗi gốc do bạn gõ ở Inspector 
		// kết hợp với animType (Stand/Walk) nếu muốn phân biệt, hoặc dùng trực tiếp:
		string baseAnim = dirName switch
		{
			"Down" => Anim_Down,
			"Down_Left" => Anim_DownLeft,
			"Down_Right" => Anim_DownRight,
			"Left" => Anim_Left,
			"Right" => Anim_Right,
			"Up" => Anim_Up,
			"Up_Left" => Anim_UpLeft,
			"Up_Right" => Anim_UpRight,
			_ => ""
		};

		// Nếu bạn muốn tự động ghép thêm hậu tố Stand/Walk (VD: "Ride_Down" thành "Ride_Stand_Down" hoặc "Ride_Walk_Down"):
		// Hoặc đơn giản là trả về luôn tên animation bạn điền trong Inspector:
		return baseAnim;
	}

	public AnimatedSprite2D GetMountSprite() => sprite;
	public Marker2D GetSeatAnchor() => GetNodeOrNull<Marker2D>("SeatAnchor");
}
