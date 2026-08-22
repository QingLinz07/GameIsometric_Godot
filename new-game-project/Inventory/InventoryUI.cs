using Godot;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

public partial class InventoryUI : Control
{

	private const int SLOTS_PER_PAGE = 25;
	private const int TOTAL_PAGES = 5;
	private int currentPage = 0;

	// Lưu trữ dữ liệu túi đồ: 5 trang x 25 slot = 125 slot tổng cộng
	private Dictionary<int, (string ItemID, int Quantity)> inventoryData = new Dictionary<int, (string, int)>();

	[Export] private GridContainer gridContainer;
	[Export] private Button[] pageButtons = new Button[TOTAL_PAGES];
	[Export] private Button autoSortButton;

	// UI Panel thông tin Item
	[Export] private Control itemInfoPanel;
	[Export] private TextureRect infoIcon;
	[Export] private RichTextLabel infoNameLabel;
	[Export] private RichTextLabel infoPhanLoaiLabel;
	[Export] private RichTextLabel infoDescLabel;
	[Export] private Button useButton;
	[Export] private Button dropButton;
	[Export] private Button splitButton;
	[Export] private Button closeInfoButton;

	// UI Popup vứt/tách item (Dạng Panel)
	[Export] private Control dropPopup;
	[Export] private Label popupTitleLabel; // Label hiển thị tiêu đề trong popup (Nhập số lượng vứt/tách)
	[Export] private LineEdit dropQuantityInput;
	[Export] private Button confirmDropButton;
	[Export] private Button closePopupButton; // Nút đóng popup

	// UI Dialog xác nhận vứt lần cuối (nếu bạn tạo thêm một AcceptDialog hoặc Panel con xác nhận)
	// Tạm thời dùng GD.Print hoặc hiển thị trực tiếp thông qua logic xác nhận bồi thêm.
	private bool isWaitingForFinalConfirmation = false;

	private SlotUI selectedSlot = null;
	private List<SlotUI> slotUIs = new List<SlotUI>();
	private bool isSplittingMode = false; // Cờ phân biệt chế độ Tách hay Vứt

	public override void _Ready()
	{
		SetupSlots();
		SetupPagination();
		SetupButtons();
		Visible = false;
		if (itemInfoPanel != null) itemInfoPanel.Visible = false;
		if (dropPopup != null) dropPopup.Visible = false;
		// Tự động yêu cầu GameManager nạp dữ liệu túi đồ ngay khi InventoryUI sẵn sàng
		CallDeferred(nameof(LoadDataFromGameManager));
	}

	private void LoadDataFromGameManager()
	{
		Node gameMgrNode = GetNodeOrNull("/root/GameManager");
		if (gameMgrNode != null)
		{
			var playerData = (Godot.Collections.Dictionary)gameMgrNode.Get("current_player_data");
			if (playerData != null && playerData.ContainsKey("inventory_data"))
			{
				var invData = (Godot.Collections.Dictionary)playerData["inventory_data"];
				LoadInventorySaveData(invData);
			}
		}
	}

	private void SetupSlots()
	{
		slotUIs.Clear();
		int index = 0;

		if (gridContainer != null)
		{
			foreach (Node child in gridContainer.GetChildren())
			{
				if (child is SlotUI slotUI)
				{
					slotUI.SlotIndex = index;
					slotUI.PageIndex = currentPage;
					slotUI.InventoryUIReference = this;
					slotUI.OnSlotClicked -= OnSlotClicked;
					slotUI.OnSlotClicked += OnSlotClicked;

					slotUIs.Add(slotUI);
					index++;
				}
			}
		}
	}

	private void SetupPagination()
	{
		for (int i = 0; i < TOTAL_PAGES; i++)
		{
			int pageIndex = i;
			if (pageButtons[i] != null)
			{
				pageButtons[i].Pressed += () => SwitchPage(pageIndex);
			}
		}
	}

	private void SetupButtons()
	{
		if (autoSortButton != null) autoSortButton.Pressed += AutoSortInventory;
		if (closeInfoButton != null) closeInfoButton.Pressed += () => itemInfoPanel.Visible = false;
		if (useButton != null) useButton.Pressed += UseSelectedItem;
		if (dropButton != null) dropButton.Pressed += RequestDropItem;
		if (splitButton != null) splitButton.Pressed += RequestSplitItem;

		if (confirmDropButton != null) confirmDropButton.Pressed += OnConfirmDropPressed;
		if (closePopupButton != null) closePopupButton.Pressed += CloseDropPopup;
	}

	private void CloseDropPopup()
	{
		if (dropPopup != null) dropPopup.Visible = false;
		if (dropQuantityInput != null) dropQuantityInput.Text = "";
		isWaitingForFinalConfirmation = false;
	}

	public void SwitchPage(int page)
	{
		currentPage = page;

		// Cập nhật lại PageIndex cho tất cả SlotUI đang hiển thị trên lưới
		foreach (var slot in slotUIs)
		{
			slot.PageIndex = currentPage;
		}

		RefreshUI();
	}

	public void RefreshUI()
	{
		int startIndex = currentPage * SLOTS_PER_PAGE;
		for (int i = 0; i < SLOTS_PER_PAGE; i++)
		{
			int globalIndex = startIndex + i;
			if (i < slotUIs.Count)
			{
				if (inventoryData.ContainsKey(globalIndex))
				{
					var data = inventoryData[globalIndex];
					ItemData itemData = ItemDatabase.Instance != null ? ItemDatabase.Instance.GetItem(data.ItemID) : null;

					if (itemData != null)
					{
						slotUIs[i].SetItem(itemData, data.Quantity);
					}
					else
					{
						slotUIs[i].ClearSlot();
					}
				}
				else
				{
					slotUIs[i].ClearSlot();
				}
			}
		}
	}

	private void OnSlotClicked(SlotUI slot)
	{
		selectedSlot = slot;
		if (itemInfoPanel != null && slot.CurrentItemData != null)
		{
			if (infoIcon != null) infoIcon.Texture = slot.CurrentItemData.Icon;
			if (infoNameLabel != null) infoNameLabel.Text = slot.CurrentItemData.ItemName;
			if (infoPhanLoaiLabel != null) infoPhanLoaiLabel.Text = slot.CurrentItemData.ItemPhanLoai;
			if (infoDescLabel != null) infoDescLabel.Text = slot.CurrentItemData.Description;
			itemInfoPanel.Visible = true;
			// Gọi trực tiếp qua biến Instance đã được map sẵn

		}
	}

	private void UseSelectedItem()
	{
		if (selectedSlot == null || selectedSlot.CurrentItemData == null) return;

		ItemData itemData = selectedSlot.CurrentItemData;
		Node playerNode = GetTree().GetFirstNodeInGroup("Player");

		if (playerNode == null)
		{
			GD.PrintErr("[Inventory] Không tìm thấy Node Player!");
			return;
		}

		bool canUse = itemData.Use(playerNode);
		if (!canUse) return;

		int globalIndex = (currentPage * SLOTS_PER_PAGE) + selectedSlot.SlotIndex;
		if (inventoryData.ContainsKey(globalIndex))
		{
			var data = inventoryData[globalIndex];
			if (data.Quantity > 1)
			{
				inventoryData[globalIndex] = (data.ItemID, data.Quantity - 1);
			}
			else
			{
				inventoryData.Remove(globalIndex);
			}
		}

		if (itemInfoPanel != null) itemInfoPanel.Visible = false;
		RefreshUI();
	}

	private void RequestDropItem()
	{
		if (selectedSlot == null) return;
		isSplittingMode = false;
		isWaitingForFinalConfirmation = false;

		// Đổi tên nhãn thành "Nhập số lượng muốn vứt"
		if (popupTitleLabel != null) popupTitleLabel.Text = "Nhập số lượng muốn vứt:";

		if (selectedSlot.Quantity > 1)
		{
			if (dropPopup != null) dropPopup.Visible = true;

		}
		else
		{
			ExecuteDrop(1);
		}
	}

	private void RequestSplitItem()
	{
		if (selectedSlot == null || selectedSlot.CurrentItemData == null) return;
		if (selectedSlot.Quantity <= 1)
		{
			SendPlayerMessage.Instance.SendMessage($"Số lượng quá ít để tách");
			return;
		}

		isSplittingMode = true;
		isWaitingForFinalConfirmation = false;

		// Đổi tên nhãn thành "Nhập số lượng muốn tách"
		if (popupTitleLabel != null) popupTitleLabel.Text = "Nhập số lượng muốn tách:";

		if (dropPopup != null) dropPopup.Visible = true;
	}

	private void OnConfirmDropPressed()
	{
		if (selectedSlot == null || dropQuantityInput == null) return;

		if (int.TryParse(dropQuantityInput.Text, out int inputAmount))
		{
			if (inputAmount > 0)
			{
				if (isSplittingMode)
				{
					inputAmount = System.Math.Min(inputAmount, selectedSlot.Quantity - 1);
					ExecuteSplit(inputAmount);
				}
				else
				{
					inputAmount = System.Math.Min(inputAmount, selectedSlot.Quantity);

					// Nếu đang ở chế độ vứt và chưa bấm xác nhận lần cuối
					if (!isWaitingForFinalConfirmation)
					{
						isWaitingForFinalConfirmation = true;
						if (popupTitleLabel != null)
							popupTitleLabel.Text = $"Xác nhận vứt {inputAmount} vật phẩm này?";
						return; // Dừng lại chờ bấm Confirm lần nữa
					}

					ExecuteDrop(inputAmount);
				}
			}
		}
		else
		{
			SendPlayerMessage.Instance.SendMessage($"Vui lòng nhập một số hợp lệ");
		}
	}

	private void ExecuteDrop(int amount)
	{
		if (selectedSlot == null) return;

		int globalIndex = (currentPage * SLOTS_PER_PAGE) + selectedSlot.SlotIndex;

		if (inventoryData.ContainsKey(globalIndex))
		{
			var data = inventoryData[globalIndex];
			int newQuantity = data.Quantity - amount;

			if (newQuantity > 0)
			{
				inventoryData[globalIndex] = (data.ItemID, newQuantity);
				SendPlayerMessage.Instance.SendMessage($"Đã vứt {amount} vật phẩm");
			}
			else
			{
				inventoryData.Remove(globalIndex);
			}
		}

		CloseDropPopup();
		if (itemInfoPanel != null) itemInfoPanel.Visible = false;
		RefreshUI();
	}

	private void ExecuteSplit(int splitAmount)
	{
		if (selectedSlot == null) return;

		int globalCurrentIndex = (currentPage * SLOTS_PER_PAGE) + selectedSlot.SlotIndex;
		if (!inventoryData.ContainsKey(globalCurrentIndex)) return;

		var currentData = inventoryData[globalCurrentIndex];
		int remainingInOriginal = currentData.Quantity - splitAmount;

		if (remainingInOriginal <= 0) return;

		int emptySlotIndex = -1;
		int maxSlots = TOTAL_PAGES * SLOTS_PER_PAGE;

		for (int i = globalCurrentIndex + 1; i < maxSlots; i++)
		{
			if (!inventoryData.ContainsKey(i))
			{
				emptySlotIndex = i;
				break;
			}
		}

		if (emptySlotIndex == -1)
		{
			for (int i = 0; i < globalCurrentIndex; i++)
			{
				if (!inventoryData.ContainsKey(i))
				{
					emptySlotIndex = i;
					break;
				}
			}
		}

		if (emptySlotIndex != -1)
		{
			inventoryData[globalCurrentIndex] = (currentData.ItemID, remainingInOriginal);
			inventoryData[emptySlotIndex] = (currentData.ItemID, splitAmount);
			SendPlayerMessage.Instance.SendMessage($"Đã tách {splitAmount} vật phẩm");
		}
		else
		{
			SendPlayerMessage.Instance.SendMessage($"Túi đồ đã đầy");
		}

		CloseDropPopup();
		if (itemInfoPanel != null) itemInfoPanel.Visible = false;
		RefreshUI();
	}

	private void AutoSortInventory()
	{
		List<(string ItemID, int Quantity)> allItems = new List<(string, int)>();
		int maxSlots = TOTAL_PAGES * SLOTS_PER_PAGE;

		for (int i = 0; i < maxSlots; i++)
		{
			if (inventoryData.ContainsKey(i))
			{
				var item = inventoryData[i];
				if (item.Quantity > 0 && !string.IsNullOrEmpty(item.ItemID))
				{
					allItems.Add(item);
				}
			}
		}

		List<(string ItemID, int Quantity)> mergedItems = new List<(string, int)>();

		foreach (var item in allItems)
		{
			ItemData itemData = ItemDatabase.Instance != null ? ItemDatabase.Instance.GetItem(item.ItemID) : null;

			if (itemData != null && itemData.IsStackable)
			{
				int remainingQty = item.Quantity;
				bool merged = false;

				for (int j = 0; j < mergedItems.Count; j++)
				{
					if (mergedItems[j].ItemID == item.ItemID)
					{
						int spaceLeft = itemData.MaxStack - mergedItems[j].Quantity;
						if (spaceLeft > 0)
						{
							int add = System.Math.Min(remainingQty, spaceLeft);
							mergedItems[j] = (mergedItems[j].ItemID, mergedItems[j].Quantity + add);
							remainingQty -= add;
						}
					}
					if (remainingQty <= 0)
					{
						merged = true;
						break;
					}
				}

				while (remainingQty > 0)
				{
					int stackAmount = System.Math.Min(remainingQty, itemData.MaxStack);
					mergedItems.Add((item.ItemID, stackAmount));
					remainingQty -= stackAmount;
				}
			}
			else
			{
				mergedItems.Add(item);
			}
		}

		mergedItems.Sort((a, b) => string.Compare(a.ItemID, b.ItemID));

		inventoryData.Clear();
		for (int i = 0; i < mergedItems.Count && i < maxSlots; i++)
		{
			inventoryData[i] = mergedItems[i];
		}

		if (itemInfoPanel != null) itemInfoPanel.Visible = false;
		RefreshUI();
	}

	public bool AddItem(ItemData newItem, int amount)
	{
		if (newItem == null || amount <= 0) return false;

		int remainingAmount = amount;

		if (newItem.IsStackable)
		{
			for (int i = 0; i < TOTAL_PAGES * SLOTS_PER_PAGE; i++)
			{
				if (inventoryData.ContainsKey(i))
				{
					var slotData = inventoryData[i];
					if (slotData.ItemID == newItem.ItemID)
					{
						int currentQuantity = slotData.Quantity;
						int spaceLeft = newItem.MaxStack - currentQuantity;

						if (spaceLeft > 0)
						{
							int addAmount = System.Math.Min(remainingAmount, spaceLeft);
							inventoryData[i] = (newItem.ItemID, currentQuantity + addAmount);
							remainingAmount -= addAmount;

							if (remainingAmount <= 0) break;
						}
					}
				}
			}
		}

		if (remainingAmount > 0)
		{
			for (int i = 0; i < TOTAL_PAGES * SLOTS_PER_PAGE; i++)
			{
				if (!inventoryData.ContainsKey(i) || inventoryData[i].Quantity <= 0)
				{
					int addAmount = newItem.IsStackable ? System.Math.Min(remainingAmount, newItem.MaxStack) : 1;
					inventoryData[i] = (newItem.ItemID, addAmount);
					remainingAmount -= addAmount;

					if (!newItem.IsStackable && remainingAmount > 0) continue;
					if (remainingAmount <= 0) break;
				}
			}
		}

		bool success = remainingAmount < amount;
		RefreshUI();
		return success;
	}

	public Godot.Collections.Dictionary GetInventorySaveData()
	{
		Godot.Collections.Dictionary saveDict = new Godot.Collections.Dictionary();

		foreach (var kvp in inventoryData)
		{
			int slotIndex = kvp.Key;
			var itemInfo = kvp.Value;

			Godot.Collections.Dictionary slotData = new Godot.Collections.Dictionary();
			slotData["item_id"] = itemInfo.ItemID;
			slotData["quantity"] = itemInfo.Quantity;

			saveDict[slotIndex.ToString()] = slotData;
		}

		return saveDict;
	}

	public void LoadInventorySaveData(Godot.Collections.Dictionary savedData)
	{
		inventoryData.Clear();

		if (savedData == null)
		{
			RefreshUI();
			return;
		}

		foreach (var key in savedData.Keys)
		{
			int slotIndex = key.ToString().ToInt();

			if (savedData[key].Obj is Godot.Collections.Dictionary slotData)
			{
				string itemID = slotData.ContainsKey("item_id") ? slotData["item_id"].ToString() : "";
				int quantity = slotData.ContainsKey("quantity") ? (int)slotData["quantity"].AsInt32() : 0;

				if (!string.IsNullOrEmpty(itemID) && quantity > 0)
				{
					inventoryData[slotIndex] = (itemID, quantity);
				}
			}
		}

		RefreshUI();
	}

	public void SwapSlots(int fromPage, int fromIndex, int toPage, int toIndex)
	{
		int globalFromIndex = (fromPage * SLOTS_PER_PAGE) + fromIndex;
		int globalToIndex = (toPage * SLOTS_PER_PAGE) + toIndex;

		if (globalFromIndex == globalToIndex) return;

		bool hasFrom = inventoryData.ContainsKey(globalFromIndex);
		bool hasTo = inventoryData.ContainsKey(globalToIndex);

		if (!hasFrom) return;

		var fromData = inventoryData[globalFromIndex];

		if (hasTo)
		{
			var toData = inventoryData[globalToIndex];
			ItemData itemData = ItemDatabase.Instance != null ? ItemDatabase.Instance.GetItem(fromData.ItemID) : null;

			if (toData.ItemID == fromData.ItemID && itemData != null && itemData.IsStackable)
			{
				int totalQty = toData.Quantity + fromData.Quantity;
				if (totalQty <= itemData.MaxStack)
				{
					inventoryData[globalToIndex] = (toData.ItemID, totalQty);
					inventoryData.Remove(globalFromIndex);
				}
				else
				{
					int remainder = totalQty - itemData.MaxStack;
					inventoryData[globalToIndex] = (toData.ItemID, itemData.MaxStack);
					inventoryData[globalFromIndex] = (fromData.ItemID, remainder);
				}
			}
			else
			{
				inventoryData[globalFromIndex] = toData;
				inventoryData[globalToIndex] = fromData;
			}
		}
		else
		{
			inventoryData[globalToIndex] = fromData;
			inventoryData.Remove(globalFromIndex);
		}

		if (itemInfoPanel != null) itemInfoPanel.Visible = false;
		RefreshUI();
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
		{
			if (keyEvent.Keycode == Key.I)
			{
				ToggleInventory();
			}
		}
	}

	public void ToggleInventory()
	{
		Visible = !Visible;

		if (Visible)
		{
			RefreshUI();
		}
		else
		{
			if (itemInfoPanel != null) itemInfoPanel.Visible = false;
			CloseDropPopup();
		}
	}
}