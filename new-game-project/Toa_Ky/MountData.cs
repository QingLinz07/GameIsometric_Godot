using Godot;

[GlobalClass]
public partial class MountData : Resource
{
	[Export] public string MountId { get; set; } = "";
	[Export] public string MountName { get; set; } = "Tên Tọa Kỵ";
	[Export] public float SpeedMultiplier { get; set; } = 1.5f;
	[Export] public string Category { get; set; } = "Thường";
	[Export(PropertyHint.MultilineText)] public string Description { get; set; } = "Mô tả tọa kỵ...";

	// Lưu đường dẫn file Icon (ví dụ: "res://Assets/Icons/Horse.png")
	[Export(PropertyHint.File, "*.png,*.webp,*.svg")]
	public string IconPath { get; set; } = "";

	// Lưu đường dẫn file Scene (ví dụ: "res://Toa_Ky/Horse/Horse.tscn")
	[Export(PropertyHint.File, "*.tscn,*.scn")]
	public string MountScenePath { get; set; } = "";
}