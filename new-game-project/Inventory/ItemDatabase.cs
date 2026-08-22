using Godot;
using System.Collections.Generic;

public partial class ItemDatabase : Node
{
	public static ItemDatabase Instance { get; private set; }

	// Danh sách các ItemData được kéo thả trực tiếp từ Inspector vào đây
	[Export] private Godot.Collections.Array<ItemData> allItems = new Godot.Collections.Array<ItemData>();

	private Dictionary<string, ItemData> itemLookupTable = new Dictionary<string, ItemData>();

	public override void _Ready()
	{
		Instance = this;
		BuildDatabase();
	}

	private void BuildDatabase()
	{
		itemLookupTable.Clear();
		foreach (var item in allItems)
		{
			if (item != null && !string.IsNullOrEmpty(item.ItemID))
			{
				if (!itemLookupTable.ContainsKey(item.ItemID))
				{
					itemLookupTable.Add(item.ItemID, item);
				}
				else
				{
					GD.PrintErr($"[ItemDatabase] Trùng lặp ItemID: {item.ItemID}");
				}
			}
		}
		GD.Print($"[ItemDatabase] Đã load thành công {itemLookupTable.Count} items vào hệ thống.");
	}

	// Hàm tra cứu ItemData dựa vào ItemID
	public ItemData GetItem(string itemID)
	{
		if (string.IsNullOrEmpty(itemID)) return null;

		if (itemLookupTable.ContainsKey(itemID))
		{
			return itemLookupTable[itemID];
		}

		GD.PrintErr($"[ItemDatabase] Không tìm thấy Item có ID: {itemID}");
		return null;
	}
}