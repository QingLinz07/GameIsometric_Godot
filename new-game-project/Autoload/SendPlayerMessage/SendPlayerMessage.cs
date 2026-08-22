using Godot;

public partial class SendPlayerMessage : CanvasLayer
{
	private RichTextLabel thongbao;
	private Vector2 _originalPosition; // Biến lưu vị trí gốc chuẩn
	private Tween _activeTween;         // Dùng để hủy tween cũ nếu thông báo mới ghi đè

	public static SendPlayerMessage Instance { get; private set; }

	public override void _EnterTree()
	{
		Instance = this;
	}

	public override void _Ready()
	{
		thongbao = GetNode<RichTextLabel>("Control/RichTextLabel");

		// Lưu lại vị trí chuẩn ban đầu mà bạn đã canh trên Editor
		_originalPosition = thongbao.Position;

		// Ẩn chữ đi ban đầu
		thongbao.Modulate = new Color(1, 1, 1, 0);
	}

	public void SendMessage(string text)
	{
		if (thongbao == null) return;

		// Nếu đang có hiệu ứng chạy dở, hủy đi để chạy cái mới
		if (_activeTween != null && _activeTween.IsValid())
		{
			_activeTween.Kill();
		}

		thongbao.Text = $"[center][outline_size=8][outline_color=black][color=white]{text}[/color][/outline_color][/outline_size][/center]";

		// Đặt vị trí bắt đầu (thấp hơn vị trí gốc 30px)
		Vector2 startPos = new Vector2(_originalPosition.X, _originalPosition.Y + 30);

		thongbao.Position = startPos;
		thongbao.Modulate = new Color(1, 1, 1, 0);

		// Tạo Tween mới
		_activeTween = CreateTween();

		// 1. Trồi lên vị trí gốc và Fade In
		_activeTween.TweenProperty(thongbao, "position", _originalPosition, 0.4f)
					.SetTrans(Tween.TransitionType.Back)
					.SetEase(Tween.EaseType.Out);

		_activeTween.Parallel().TweenProperty(thongbao, "modulate:a", 1.0f, 0.3f);

		// 2. Chờ 2 giây
		_activeTween.TweenInterval(2.0f);

		// 3. Fade Out (mờ dần)
		_activeTween.TweenProperty(thongbao, "modulate:a", 0.0f, 0.5f);
	}
}