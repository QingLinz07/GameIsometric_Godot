using Godot;

[GlobalClass]
public partial class ItemData : Resource
{
	[Export] public string ItemID { get; set; } = "";
	[Export] public string ItemName { get; set; } = "";
	[Export] public Texture2D Icon { get; set; }
	[Export] public string Description { get; set; } = "";
	[Export] public string ItemPhanLoai { get; set; } = "";
	[Export] public bool IsStackable { get; set; } = true;
	[Export] public int MaxStack { get; set; } = 99;

	// HÀM SỬ DỤNG CHUNG (Virtual để các item con viết đè code riêng)
	// Trả về true nếu dùng thành công (để trừ item), false nếu thất bại
	public virtual bool Use(Node character)
	{
		GD.Print($"Đã sử dụng item cơ bản: {ItemName}");
		return true;
	}
}