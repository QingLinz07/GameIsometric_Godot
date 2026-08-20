using Godot;

public partial class DamagePopup : Node2D
{
	private Label _label;
	private float _duration = 0.8f;
	private Vector2 _velocity = new Vector2(0, -80);

	public override async void _Ready()
	{
		_label = GetNode<Label>("Label");

		var tween = CreateTween().SetParallel(true);

		// Hiệu ứng bay lên trên
		tween.TweenProperty(this, "position", Position + _velocity * _duration, _duration)
			 .SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Quad);

		// Hiệu ứng mờ dần
		tween.TweenProperty(_label, "modulate:a", 0f, _duration)
			 .SetEase(Tween.EaseType.In).SetTrans(Tween.TransitionType.Linear);

		// Chờ hết thời gian rồi tự hủy node
		await ToSignal(GetTree().CreateTimer(_duration), SceneTreeTimer.SignalName.Timeout);
		QueueFree();
	}

	/// <summary>
	/// Khởi tạo damage popup với các tùy chọn nâng cao
	/// </summary>
	/// <param name="amount">Số sát thương</param>
	/// <param name="fontSize">Cỡ chữ (mặc định 24)</param>
	/// <param name="textColor">Màu sắc chữ (mặc định Trắng)</param>
	/// <param name="customFont">File Font tùy chỉnh (FontFile), nếu null sẽ dùng font mặc định</param>
	/// <param name="randomOffset">Có làm lệch vị trí ngẫu nhiên một chút không (tránh đè chữ)</param>
	public void Initialize(float amount, int fontSize = 24, Color? textColor = null, FontFile customFont = null, bool randomOffset = true)
	{
		_label = GetNode<Label>("Label");
		_label.Text = amount.ToString("F0");

		// 1. Chỉnh Font Size (Sử dụng theme override của Label)
		_label.AddThemeFontSizeOverride("font_size", fontSize);

		// 2. Chỉnh Màu sắc (Nếu không truyền vào thì mặc định là màu Trắng hoặc Vàng)
		_label.AddThemeColorOverride("font_color", textColor ?? new Color(1, 1, 1));

		// 3. Chỉnh FontFamily (Nếu có truyền file font .ttf/.tres vào)
		if (customFont != null)
		{
			_label.AddThemeFontOverride("font", customFont);
		}

		// 4. Lệch vị trí ngẫu nhiên (Giúp khi đánh liên tục các số không bị dính vào nhau)
		if (randomOffset)
		{
			float randomX = (float)GD.RandRange(-25, 25);
			float randomY = (float)GD.RandRange(-10, 10);
			Position += new Vector2(randomX, randomY);
		}
	}
}