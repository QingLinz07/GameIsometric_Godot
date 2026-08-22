using Godot;

public partial class SlotUI : Button // Đổi từ Control về lại Button
{
	[Export] private TextureRect iconTexture;
	[Export] private Label quantityLabel;

	public int SlotIndex { get; set; }
	public int PageIndex { get; set; }
	public ItemData CurrentItemData { get; private set; }
	public int Quantity { get; private set; }

	// Không cần biến [Export] private Button slotButton nữa vì chính node gốc đã là Button!

	[System.NonSerialized]
	public InventoryUI InventoryUIReference;

	[Signal]
	public delegate void OnSlotClickedEventHandler(SlotUI slot);

	public override void _Ready()
	{
		// Khi chính nó là Button, ta bắt sự kiện Pressed trực tiếp luôn:
		Pressed += () => EmitSignal(SignalName.OnSlotClicked, this);
	}

	public void SetItem(ItemData itemData, int quantity)
	{
		CurrentItemData = itemData;
		Quantity = quantity;

		if (iconTexture != null && itemData != null && itemData.Icon != null)
		{
			iconTexture.Texture = itemData.Icon;
			iconTexture.Visible = true;
		}

		if (quantityLabel != null)
		{
			quantityLabel.Text = quantity > 1 ? quantity.ToString() : "";
			quantityLabel.Visible = quantity > 1;
		}
	}

	public void ClearSlot()
	{
		CurrentItemData = null;
		Quantity = 0;

		if (iconTexture != null)
		{
			iconTexture.Texture = null;
			iconTexture.Visible = false;
		}

		if (quantityLabel != null)
		{
			quantityLabel.Text = "";
			quantityLabel.Visible = false;
		}
	}

	// --- TÍNH NĂNG KÉO (DRAG) ---
	public override Variant _GetDragData(Vector2 atPosition)
	{
		if (CurrentItemData == null) return default;

		var preview = new TextureRect();
		preview.Texture = CurrentItemData.Icon;
		preview.ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize;
		preview.CustomMinimumSize = new Vector2(40, 40);

		var previewContainer = new Control();
		previewContainer.AddChild(preview);
		preview.Position = new Vector2(-20, -20);
		SetDragPreview(previewContainer);

		var data = new Godot.Collections.Dictionary();
		data["from_page"] = PageIndex;
		data["from_index"] = SlotIndex;
		return data;
	}

	// --- KIỂM TRA THẢ (DROP) ---
	public override bool _CanDropData(Vector2 atPosition, Variant data)
	{
		// 1. Kiểm tra xem dữ liệu kéo đi có phải là dictionary của inventory không
		if (data.VariantType == Variant.Type.Dictionary)
		{
			var dict = data.AsGodotDictionary();
			if (dict.ContainsKey("from_page") && dict.ContainsKey("from_index"))
			{
				// 2. Đảm bảo ô hiện tại (ô nhận thả) cũng là một SlotUI hợp lệ và có gắn InventoryUIReference
				// Điều này chặn tuyệt đối việc thả vào các Panel hoặc UI khác không phải ô chứa đồ.
				if (InventoryUIReference != null)
				{
					return true;
				}
			}
		}
		return false;
	}

	// --- XỬ LÝ KHI THẢ (DROP) ---
	public override void _DropData(Vector2 atPosition, Variant data)
	{
		if (data.VariantType == Variant.Type.Dictionary)
		{
			var dict = data.AsGodotDictionary();
			int fromPage = (int)dict["from_page"].AsInt32();
			int fromIndex = (int)dict["from_index"].AsInt32();
			int toPage = PageIndex;
			int toIndex = SlotIndex;

			if (InventoryUIReference != null)
			{
				InventoryUIReference.SwapSlots(fromPage, fromIndex, toPage, toIndex);
			}
		}
	}
}
