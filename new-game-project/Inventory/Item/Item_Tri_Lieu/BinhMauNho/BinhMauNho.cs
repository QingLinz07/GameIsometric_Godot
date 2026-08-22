using Godot;


[GlobalClass]
public partial class BinhMauNho : ItemData
{
	[Export] public int HealAmount = 20;

	public override bool Use(Node character)
	{
		var playerManager = character.GetTree().Root.GetNodeOrNull("PlayerManager");
		if (playerManager != null)
		{
			float max_hp = (float)playerManager.Call("get_max_hp");
			float current_hp = (float)playerManager.Call("get_hp");
			if (current_hp < max_hp)
			{
				playerManager.Call("CongMau", (float)HealAmount);
				SendPlayerMessage.Instance.SendMessage($"Đã hồi {HealAmount} máu");
				return true;
			}
			SendPlayerMessage.Instance.SendMessage($"Máu đã đầy, không thể sử dụng!");
		}
		return false;
	}
}

// 2. Dành cho Sách học kỹ năng
// [GlobalClass]
// public partial class SkillBookItemData : ItemData
// {
// 	[Export] public string SkillIDToLearn = "fireball";

// 	public override bool Use(Node character)
// 	{
// 		if (character.HasMethod("LearnSkill"))
// 		{
// 			Variant success = character.Call("LearnSkill", SkillIDToLearn);
// 			if (success.VariantType == Variant.Type.Bool)
// 			{
// 				return success.AsBool();
// 			}
// 		}

// 		GD.Print($"Đã học kỹ năng mới: {SkillIDToLearn}");
// 		return true;
// 	}
// }