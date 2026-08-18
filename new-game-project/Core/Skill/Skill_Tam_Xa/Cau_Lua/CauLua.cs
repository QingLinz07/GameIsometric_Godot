using Godot;
using System;

public partial class CauLua : BaseSkillTamXa
{

	public override float Stamina { get; set; } = 5f;
	public override float Damage { get; set; } = 10f;
	public override float Cooldown { get; set; } = 2f;

	protected override float speed { get; set; } = 400f;
	protected override float max_range { get; set; } = 200f;

}
