using Godot;
using System;

public partial class HealthSystem : Node
{
    [Export]
    private float current_hp { get; set; }
    [Export]
    private float max_hp { get; set; }
    public HealthSystem() {}
    public void Initialize(float p_max_hp, float p_current_hp)
    {
        max_hp = p_max_hp;
        current_hp = p_current_hp;
    }
    public void CongMau(float amount)
    {
        if (amount < 0) return;
        if (current_hp + amount > max_hp)
        {
            amount = max_hp - current_hp;
            current_hp += amount;
        }
        else
        {
            current_hp += amount;
        }
    }
    public void TruMau(float amount)
    {
        if (amount < 0) return;
        if (current_hp - amount < 0)
        {
            amount = current_hp;
            current_hp -= amount;
        }
        else
        {
            current_hp -= amount;
        }
    }
}