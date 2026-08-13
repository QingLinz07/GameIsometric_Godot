using Godot;
using System;

public partial class StaminaSystem : Node
{
	[Export]
    private float current_stamina { get; set; }
    [Export]
    private float max_stamina { get; set; }

    public StaminaSystem() {}

    public void Initialize(float p_max_stamina, float p_current_stamina)
    {
        max_stamina = p_max_stamina;
        current_stamina = p_current_stamina;
    }

    public void CongStamina(float amount)
    {
        if (amount < 0) return;
        if (current_stamina + amount > max_stamina)
        {
            amount = max_stamina - current_stamina;
            current_stamina += amount;
        }
        else
        {
            current_stamina += amount;
        }
    }

    public void TruStamina(float amount)
    {
        if (amount < 0) return;
        if (current_stamina - amount < 0)
        {
            amount = current_stamina;
            current_stamina -= amount;
        }
        else
        {
            current_stamina -= amount;
        }
    }
}
