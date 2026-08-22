using Godot;
using System.Collections.Generic;

public partial class SoundManager : Control
{
	// Cho phép kéo thả danh sách các Button từ Inspector vào mảng này
	[Export]
	private Godot.Collections.Array<Button> _buttons = new();

	// Kéo thả AudioStreamPlayer từ Inspector vào đây
	[Export]
	private AudioStreamPlayer _audioPlayer;

	public override void _Ready()
	{
		foreach (var button in _buttons)
		{
			if (button != null)
			{
				// Kiểm tra xem nút đã được kết nối tới hàm PlaySound chưa (nếu dùng phương thức thường thay vì lambda)
				// Hoặc đơn giản là dùng phương thức Connect của Godot với cờ Safe

				// Cách an toàn với Godot C# Signal:
				if (!button.IsConnected(Button.SignalName.Pressed, Callable.From(PlaySound)))
				{
					button.Pressed += PlaySound;
				}
			}
		}
	}

	private void PlaySound()
	{
		if (_audioPlayer != null && _audioPlayer.Stream != null)
		{
			_audioPlayer.Play();
		}
	}
}