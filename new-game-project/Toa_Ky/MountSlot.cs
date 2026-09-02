using System;
using Godot;

public partial class MountSlot : Button
{
	[Export] private TextureRect iconRect;
	[Export] private Label nameLabel;
	[Export] private TextureRect bgRect;
	[Export] private TextureRect lockIcon; // Biến gán hình ổ khóa

	public Action<MountData> OnSlotClicked;
	private MountData mountData;
	private bool isOwned;

	public override void _Ready()
	{
		// Tự động tìm node nếu chưa gán trong Inspector
		if (iconRect == null) iconRect = GetNodeOrNull<TextureRect>("IconRect");
		if (nameLabel == null) nameLabel = GetNodeOrNull<Label>("NameLabel");
		if (bgRect == null) bgRect = GetNodeOrNull<TextureRect>("Background");
		if (lockIcon == null) lockIcon = GetNodeOrNull<TextureRect>("LockIcon");

		Pressed += _on_slot_pressed;
	}

	public void Setup(MountData data, bool owned)
	{
		mountData = data;
		isOwned = owned;

		if (mountData == null) return;

		// 1. Gán Icon (Lazy loading từ IconPath)
		if (iconRect != null)
		{
			if (!string.IsNullOrEmpty(mountData.IconPath))
			{
				// Chỉ nạp Texture vào RAM ngay khi Setup slot UI này
				iconRect.Texture = GD.Load<Texture2D>(mountData.IconPath);
			}
			else
			{
				iconRect.Texture = null;
			}
		}

		// 2. Gán Tên lên Slot
		if (nameLabel != null)
		{
			nameLabel.Text = mountData.MountName;
		}

		// 3. Xử lý độ mờ và hiển thị ổ khóa nếu chưa sở hữu
		if (!isOwned)
		{
			Modulate = new Color(1, 1, 1, 0.4f); // Làm mờ slot 40%

			if (lockIcon != null)
				lockIcon.Visible = true;     // Hiển thị ổ khóa
		}
		else
		{
			Modulate = new Color(1, 1, 1, 1.0f); // Hiển thị bình thường

			if (lockIcon != null)
				lockIcon.Visible = false;    // Ẩn ổ khóa
		}
	}

	private void _on_slot_pressed()
	{
		OnSlotClicked?.Invoke(mountData);
	}

	// Khi đóng giao diện/xóa slot, tự động bỏ tham chiếu Texture để giải phóng RAM
	public override void _ExitTree()
	{
		if (iconRect != null)
		{
			iconRect.Texture = null;
		}
		Pressed -= _on_slot_pressed;
	}
}