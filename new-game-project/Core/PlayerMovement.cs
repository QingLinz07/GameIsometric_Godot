using Godot;
using System.Collections.Generic;
using System;

public partial class PlayerMovement : Node
{
    private CharacterBody2D body;
    private AnimatedSprite2D sprite;
    private Node2D shadow;
    private NavigationAgent2D navigationAgent;

    private float speed;
    private float originalSpeed;
    private float turnSmoothness;
    private string lastDirectionName = "Down";
    private Vector2 animMoveDir = Vector2.Zero;
    private bool isMovingToTarget = false;

    private BaseMount activeMount = null;
    private bool isRiding = false;

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

    public void PlayerMovementCreate(CharacterBody2D pBody, AnimatedSprite2D pSprite, Node2D pShadow, NavigationAgent2D pAgent, float pSpeed, float pSmoothness)
    {
        body = pBody;
        sprite = pSprite;
        shadow = pShadow;
        navigationAgent = pAgent;
        speed = pSpeed;
        originalSpeed = pSpeed;
        turnSmoothness = pSmoothness;

        if (navigationAgent != null)
        {
            navigationAgent.PathDesiredDistance = 16.0f;
            navigationAgent.TargetDesiredDistance = 10.0f;
            navigationAgent.AvoidanceEnabled = false;
        }
    }

    public void HandleInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
        {
            if (mouseEvent.ButtonIndex == MouseButton.Right)
            {
                Vector2 clickPosition = body.GetGlobalMousePosition();
                if (navigationAgent != null)
                {
                    navigationAgent.TargetPosition = clickPosition;
                    isMovingToTarget = true;
                }
            }
        }

        if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
        {
            if (keyEvent.Keycode == Key.B)
            {
                // Kiểm tra nếu nhân vật đang di chuyển thì không cho phép cưỡi/xuống ngựa
                if (isMovingToTarget || (body != null && body.Velocity.Length() > 5.0f))
                {
                    GD.Print("[PlayerMovement] Không thể lên/xuống ngựa khi đang di chuyển! Hãy đứng lại trước.");
                    return; // Thoát ra, không thực hiện ToggleMount()
                }

                ToggleMount();
            }
        }
    }

    public void HandlePhysics(double delta)
    {
        if (!isMovingToTarget || navigationAgent == null || navigationAgent.IsNavigationFinished())
        {
            isMovingToTarget = false;
            body.Velocity = Vector2.Zero;
            StopMovement();

            if (isRiding && activeMount != null)
            {
                UpdateMountPosition();
            }
            return;
        }

        Vector2 nextPathPosition = navigationAgent.GetNextPathPosition();
        Vector2 targetDir = body.GlobalPosition.DirectionTo(nextPathPosition);

        Vector2 targetVelocity = targetDir * speed;
        float weight = Mathf.Clamp(15.0f * (float)delta, 0.0f, 1.0f);
        body.Velocity = body.Velocity.Lerp(targetVelocity, weight);
        body.MoveAndSlide();

        if (isRiding && activeMount != null)
        {
            UpdateMountPosition();
        }

        Vector2 actualDir = body.GetRealVelocity().Length() > 5.0f ? body.GetRealVelocity().Normalized() : targetDir;

        if (actualDir != Vector2.Zero)
        {
            if (animMoveDir == Vector2.Zero)
            {
                animMoveDir = actualDir;
            }
            else
            {
                animMoveDir = animMoveDir.Slerp(actualDir, turnSmoothness * (float)delta).Normalized();
            }

            string newDirName = Get8WayDirectionName(animMoveDir);
            if (newDirName != lastDirectionName || sprite.Animation != GetCurrentAnimName("Walk", newDirName))
            {
                lastDirectionName = newDirName;
                PlayCorrectAnimation("Walk", lastDirectionName);
                UpdateZIndexByDirection(lastDirectionName);
                UpdateShadowPosition(lastDirectionName);
            }
        }
    }

    private void UpdateMountPosition()
    {
        if (activeMount == null) return;

        var seat = activeMount.GetSeatAnchor();
        if (seat != null)
        {
            Vector2 offset = seat.GlobalPosition - activeMount.GlobalPosition;
            activeMount.GlobalPosition = body.GlobalPosition - offset;
        }
        else
        {
            activeMount.GlobalPosition = body.GlobalPosition;
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
        PlayCorrectAnimation("Stand", lastDirectionName);
        UpdateZIndexByDirection(lastDirectionName);
        UpdateShadowPosition(lastDirectionName);
    }

    private void PlayCorrectAnimation(string animType, string dirName)
    {
        if (sprite == null) return;

        if (isRiding && activeMount != null)
        {
            // Lấy trực tiếp tên animation tùy chỉnh từ Inspector của con tọa kỵ
            string customAnim = activeMount.GetCustomPlayerAnimation(dirName, animType);

            // Nếu bạn nhập tên cụ thể trên Inspector, ưu tiên chạy nó
            if (!string.IsNullOrEmpty(customAnim) && sprite.SpriteFrames.HasAnimation(customAnim))
            {
                if (sprite.Animation != customAnim) sprite.Play(customAnim);
            }
            else
            {
                // Fallback về cơ chế cũ nếu chưa cấu hình trên Inspector
                string rideAnim = $"Ride_{animType}_{dirName}";
                if (sprite.SpriteFrames.HasAnimation(rideAnim))
                {
                    if (sprite.Animation != rideAnim) sprite.Play(rideAnim);
                }
                else
                {
                    string normalAnim = $"{animType}_{dirName}";
                    if (sprite.Animation != normalAnim) sprite.Play(normalAnim);
                }
            }

            activeMount.PlayMountAnimation(animType, dirName);
        }
        else
        {
            string normalAnim = $"{animType}_{dirName}";
            if (sprite.Animation != normalAnim) sprite.Play(normalAnim);
        }
    }

    // Đọc trực tiếp cấu hình Z-Index từ con tọa kỵ đang cưỡi theo hướng hiện tại
    private void UpdateZIndexByDirection(string dirName)
    {
        if (!isRiding || activeMount == null || sprite == null) return;

        // Lấy Z-Index do bạn tự định nghĩa trên Inspector của con tọa kỵ đó
        sprite.ZIndex = activeMount.GetZIndexForDirection(dirName);
    }

    private string GetCurrentAnimName(string animType, string dirName)
    {
        if (isRiding && activeMount != null)
        {
            string customAnim = activeMount.GetCustomPlayerAnimation(dirName, animType);
            if (!string.IsNullOrEmpty(customAnim) && sprite != null && sprite.SpriteFrames.HasAnimation(customAnim))
            {
                return customAnim;
            }

            string rideAnim = $"Ride_{animType}_{dirName}";
            if (sprite != null && sprite.SpriteFrames.HasAnimation(rideAnim)) return rideAnim;
        }
        return $"{animType}_{dirName}";
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

    private void ToggleMount()
    {
        var gm = body.GetNodeOrNull("/root/GameManager");
        if (gm == null) return;

        var data = (Godot.Collections.Dictionary)gm.Get("current_player_data");
        if (data == null || !data.ContainsKey("equipped_mount")) return;

        string equippedId = (string)data["equipped_mount"];
        if (string.IsNullOrEmpty(equippedId)) return;

        if (!isRiding)
        {
            // 1. Lấy Manager
            var mountDb = body.GetNodeOrNull<MountDatabaseManager>("/root/MountDatabaseManager");
            if (mountDb == null) return;

            // 2. Lấy dữ liệu config
            MountData mountData = mountDb.GetMountData(equippedId);
            if (mountData == null || string.IsNullOrEmpty(mountData.MountScenePath)) return;

            // 3. LAZY LOADING: Bây giờ mới nạp Scene + PNG vào RAM
            var packedScene = GD.Load<PackedScene>(mountData.MountScenePath);
            if (packedScene == null)
            {
                GD.PrintErr($"[PlayerMovement] Không thể load scene từ đường dẫn: {mountData.MountScenePath}");
                return;
            }

            BaseMount mountNode = packedScene.Instantiate() as BaseMount;
            if (mountNode != null)
            {
                activeMount = mountNode;
                body.GetTree().CurrentScene.AddChild(activeMount);
                activeMount.GlobalPosition = body.GlobalPosition;

                var seat = activeMount.GetSeatAnchor();
                if (seat != null)
                {
                    Vector2 offset = seat.GlobalPosition - activeMount.GlobalPosition;
                    activeMount.GlobalPosition = body.GlobalPosition - offset;
                }

                float bonusSpeed = mountNode.SpeedBonus;
                speed = originalSpeed + bonusSpeed;

                GD.Print($"[PlayerMovement] Tốc độ gốc: {originalSpeed}, Bonus: {bonusSpeed}, Tổng: {speed}");

                isRiding = true;
                UpdateZIndexByDirection(lastDirectionName);
                GD.Print("[PlayerMovement] Đã lên ngựa thành công!");
            }
        }
        else
        {
            // 4. UNLOADING TRIỆT ĐỂ: Xuống ngựa & Ép xả RAM ngay lập tức
            if (activeMount != null)
            {
                if (sprite != null) sprite.ZIndex = 0;

                Vector2 exitPos = activeMount.GlobalPosition + new Vector2(40, 0);
                body.GlobalPosition = exitPos;

                // BƯỚC A: Ngắt toàn bộ tham chiếu Sprite/Animation của con thú
                UnloadMountTextures(activeMount);

                // BƯỚC B: Hủy Node khỏi Scene Tree
                activeMount.QueueFree();
                activeMount = null;

                // BƯỚC C: Ép C# và Godot thu gom rác + giải phóng VRAM ngay lập tức
                UnloadUnusedResourcesExplicitly();
            }

            speed = originalSpeed;
            isRiding = false;
            PlayStandAnimation();
            GD.Print("[PlayerMovement] Đã xuống ngựa và giải phóng RAM/VRAM lập tức!");
        }
    }

    // --- HÀM BỔ TRỢ 1: Xóa triệt để các tham chiếu Texture/Animation ---
    private void UnloadMountTextures(Node mountNode)
    {
        if (mountNode == null) return;

        // Tìm và ngắt AnimatedSprite2D
        foreach (Node child in mountNode.FindChildren("*", "AnimatedSprite2D", recursive: true, owned: false))
        {
            if (child is AnimatedSprite2D animSprite)
            {
                animSprite.Stop();
                animSprite.SpriteFrames = null; // Hủy liên kết bộ ảnh animation khỏi node
            }
        }

        // Tìm và ngắt Sprite2D
        foreach (Node child in mountNode.FindChildren("*", "Sprite2D", recursive: true, owned: false))
        {
            if (child is Sprite2D sprite2D)
            {
                sprite2D.Texture = null; // Hủy liên kết ảnh tĩnh khỏi node
            }
        }
    }

    // --- HÀM BỔ TRỢ 2: Lệnh ép C# và Godot xả RAM ngay lập tức ---
    private void UnloadUnusedResourcesExplicitly()
    {
        // 1. Ép C# Garbage Collector dọn dẹp các wrapper object
        GC.Collect();
        GC.WaitForPendingFinalizers();

        // 2. Đẩy các lệnh xử lý đồ họa còn dư thừa để Godot giải phóng VRAM ngay frame này
        RenderingServer.FreeRid(new Rid());
    }
}