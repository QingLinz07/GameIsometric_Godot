using Godot;
using System.Collections.Generic;

public partial class PlayerMovement: Node
{
    private CharacterBody2D body;
    private AnimatedSprite2D sprite;
    private Node2D shadow;

    private float speed;
    private float turnSmoothness;
    private string lastDirectionName = "Down";
    private Vector2 animMoveDir = Vector2.Zero;

    private readonly Dictionary<string, Vector2> shadowOffsets = new Dictionary<string, Vector2>()
    {
        { "Right", new Vector2(0, 30) },
        { "Down_Right", new Vector2(0, 30) },
        { "Down", new Vector2(0, 30) },
        { "Down_Left", new Vector2(0, 30) },
        { "Left", new Vector2(0, 30) },
        { "Up_Left", new Vector2(0, 30) },
        { "Up", new Vector2(0, 30) },
        { "Up_Right", new Vector2(0, 30) }
    };

    public void PlayerMovementCreate(CharacterBody2D pBody, AnimatedSprite2D pSprite, Node2D pShadow, float pSpeed, float pSmoothness)
    {
        body = pBody;
        sprite = pSprite;
        shadow = pShadow;
        speed = pSpeed;
        turnSmoothness = pSmoothness;
    }

    public void HandlePhysics(double delta)
    {
        Vector2 inputDir = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");

        if (inputDir != Vector2.Zero)
        {
            inputDir = inputDir.Normalized();
            body.Velocity = inputDir * speed;
            body.MoveAndSlide();

            if (animMoveDir == Vector2.Zero)
            {
                animMoveDir = inputDir;
            }
            else
            {
                animMoveDir = animMoveDir.Slerp(inputDir, turnSmoothness * (float)delta).Normalized();
            }

            string newDirName = Get8WayDirectionName(animMoveDir);
            if (newDirName != lastDirectionName || sprite.Animation != "Walk_" + newDirName)
            {
                lastDirectionName = newDirName;
                sprite.Play("Walk_" + lastDirectionName);
                UpdateShadowPosition(lastDirectionName);
            }
        }
        else
        {
            body.Velocity = Vector2.Zero;
            StopMovement();
        }
    }

    public void StopMovement()
    {
        animMoveDir = Vector2.Zero;
        body.Velocity = Vector2.Zero;
        PlayStandAnimation();
    }

    public void PlayStandAnimation()
    {
        string standAnimName = "Stand_" + lastDirectionName;
        if (sprite.Animation != standAnimName)
        {
            sprite.Play(standAnimName);
            UpdateShadowPosition(lastDirectionName);
        }
    }

    private void UpdateShadowPosition(string dirName)
    {
        if (shadow != null && shadowOffsets.ContainsKey(dirName))
        {
            var tween = body.CreateTween();
            tween.TweenProperty(shadow, "position", shadowOffsets[dirName], 0.15);
            tween.SetTrans(Tween.TransitionType.Sine);
        }
    }

    private string Get8WayDirectionName(Vector2 dir)
    {
        float angle = Mathf.PosMod(Mathf.RadToDeg(dir.Angle()), 360.0f);

        if (angle >= 330.0f || angle < 30.0f)
            return "Right";
        else if (angle >= 30.0f && angle < 120.0f)
            return angle < 75.0f ? "Down_Right" : "Down";
        else if (angle >= 120.0f && angle < 150.0f)
            return "Down_Left";
        else if (angle >= 150.0f && angle < 210.0f)
            return "Left";
        else if (angle >= 210.0f && angle < 300.0f)
            return angle < 255.0f ? "Up_Left" : "Up";
        else
            return "Up_Right";
    }
}