using Godot;

[GlobalClass]
public partial class MountData : Resource
{
	[Export] public string MountId { get; set; } = "";
	[Export] public string MountName { get; set; } = "Tên Tọa Kỵ";
	[Export] public float SpeedMultiplier { get; set; } = 1.5f;
	[Export] public string Category { get; set; } = "Thường";
	[Export(PropertyHint.MultilineText)] public string Description { get; set; } = "Mô tả tọa kỵ...";
	[Export] public Texture2D Icon { get; set; }
	[Export] public PackedScene MountScene { get; set; }
}