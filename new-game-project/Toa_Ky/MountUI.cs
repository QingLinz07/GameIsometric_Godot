using Godot;
using Godot.Collections;

public partial class MountUI : Control
{
	[Export] private PackedScene slotScene; // Kéo file MountSlot.tscn vào đây
	[Export] private GridContainer gridContainer;
	[Export] private Array<MountData> allMountsDatabase; // Danh sách tất cả MountData trong Inspector

	[Export] private Control popupPanel;
	[Export] private TextureRect popupIcon;
	[Export] private Label popupName;
	[Export] private RichTextLabel popupCategory;
	[Export] private RichTextLabel popupDesc;
	[Export] private Button summonButton;
	[Export] private Button closePopupButton;

	[Export] private Key toggleKey = Key.M; // Phím tắt để mở/đóng giao diện (có thể đổi trong Inspector)

	private MountData selectedMountData;

	public override void _Ready()
	{
		Hide();
		if (popupPanel != null) popupPanel.Hide();

		if (closePopupButton != null)
			closePopupButton.Pressed += () => popupPanel.Hide();

		if (summonButton != null)
			summonButton.Pressed += OnSummonButtonPressed;
	}

	// Bắt sự kiện bàn phím toàn cục để mở/đóng UI bằng phím M
	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
		{
			if (keyEvent.Keycode == toggleKey)
			{
				ToggleUI();
			}
		}
	}

	public void ToggleUI()
	{
		if (Visible)
		{
			Hide();
			if (popupPanel != null) popupPanel.Hide(); // Đóng luôn popup nếu đang mở
		}
		else
		{
			Show();
			RefreshGrid();
		}
	}

	public void RefreshGrid()
	{
		foreach (Node child in gridContainer.GetChildren())
		{
			child.QueueFree();
		}

		var gm = GetNode("/root/GameManager");
		var data = (Godot.Collections.Dictionary)gm.Get("current_player_data");
		Array ownedList = data.ContainsKey("owned_mounts") ? (Array)data["owned_mounts"] : new Array();

		foreach (var mountData in allMountsDatabase)
		{
			var slot = slotScene.Instantiate<MountSlot>();
			gridContainer.AddChild(slot);

			bool isOwned = ownedList.Contains(mountData.MountId);
			slot.Setup(mountData, isOwned);

			// Khi click vào ô vuông slot -> hiện Popup thông tin chi tiết
			slot.OnSlotClicked += (clickedData) =>
			{
				OpenPopup(clickedData, isOwned);
			};
		}
	}

	private void OpenPopup(MountData mountData, bool isOwned)
	{
		selectedMountData = mountData;
		if (popupPanel == null) return;

		popupPanel.Show();
		if (popupIcon != null) popupIcon.Texture = mountData.Icon;
		if (popupName != null) popupName.Text = mountData.MountName;
		if (popupCategory != null) popupCategory.Text = $"{mountData.Category}";
		if (popupDesc != null) popupDesc.Text = mountData.Description;

		var gm = GetNode("/root/GameManager");
		var data = (Godot.Collections.Dictionary)gm.Get("current_player_data");
		string equippedId = data.ContainsKey("equipped_mount") ? (string)data["equipped_mount"] : "";

		if (!isOwned)
		{
			summonButton.Text = "Chưa sở hữu";
			summonButton.Disabled = true;
		}
		else
		{
			summonButton.Disabled = false;
			if (mountData.MountId == equippedId)
			{
				summonButton.Text = "Đã triệu hồi";
				summonButton.Disabled = true;
			}
			else
			{
				summonButton.Text = "Trang bị";
			}
		}
	}

	private void OnSummonButtonPressed()
	{
		if (selectedMountData == null) return;

		var gm = GetNode("/root/GameManager");
		var data = (Godot.Collections.Dictionary)gm.Get("current_player_data");

		data["equipped_mount"] = selectedMountData.MountId;
		gm.Call("save_current_player"); // Lưu thẳng vào file JSON

		OpenPopup(selectedMountData, true); // Cập nhật lại nút thành "Đã triệu hồi"
		RefreshGrid();
	}
}