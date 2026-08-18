using Godot;
using System.Linq;

public partial class Enemy : CharacterBody2D
{
	[ExportGroup("Stats")]
	[Export] public string EnemyName { get; set; } = "Enemy";
	[Export] public float MaxHealth { get; set; } = 100f;
	[Export] public float MoveSpeed { get; set; } = 120f;
	[Export] public float Damage { get; set; } = 10f;
	[Export] public float respawnTime = 5.0f;          // Thời gian chờ spawn
	[Export] public int maxRespawnCount = 3;

	private bool isInitialized = false;

	[ExportGroup("Behavior Settings")]
	[Export] public float AttackCooldown { get; set; } = 1.5f;
	[Export] public NodePath PatrolAreaPath; // Kéo thả Area2D khoanh vùng tuần tra vào đây

	protected float currentHealth;
	protected Node2D targetPlayer;
	protected bool isAttacking = false;
	protected float attackTimer = 0f;

	[Export] private NodePath hurtboxPath = "Hurtbox";
	private Area2D hurtbox;
	protected Area2D patrolArea;
	protected CollisionPolygon2D patrolPolygon;
	protected Vector2[] cachedPolygonPoints;

	protected Vector2 currentPatrolTarget;
	protected float patrolWaitTimer = 0f;
	protected bool isWaitingAtPatrolPoint = false;
	protected Vector2 lastFacingDirection = new Vector2(0, 1);

	// Tham chiếu các node giao diện và hiển thị
	protected AnimatedSprite2D animSprite;
	protected Label nameTagLabel;
	protected ProgressBar healthBar;

	public override void _Ready()
	{
		currentHealth = MaxHealth;
		GD.Randomize();

		animSprite = GetNodeOrNull<AnimatedSprite2D>("AnimatedSprite2D");
		nameTagLabel = GetNodeOrNull<Label>("UI/NameTagLabel");
		healthBar = GetNodeOrNull<ProgressBar>("UI/HealthBar");


		hurtbox = GetNode<Area2D>(hurtboxPath);
		if (hurtbox != null)
		{
			// Kết nối signal khi có Area2D khác (như Hitbox của Skill) chạm vào Hurtbox
			hurtbox.AreaEntered += OnHurtboxAreaEntered;
		}

		if (nameTagLabel != null) nameTagLabel.Text = EnemyName;
		UpdateHealthBar();

		SetupPatrolArea();
		currentPatrolTarget = GetRandomPointInPatrolArea();

		var aggroArea = GetNodeOrNull<Area2D>("AggroArea");
		if (aggroArea != null)
		{
			aggroArea.BodyEntered += OnAggroBodyEntered;
			aggroArea.BodyExited += OnAggroBodyExited;
		}

		var attackArea = GetNodeOrNull<Area2D>("AttackArea");
		if (attackArea != null)
		{
			attackArea.BodyEntered += OnAttackAreaBodyEntered;
			attackArea.BodyExited += OnAttackAreaBodyExited;
		}
	}

	private void OnHurtboxAreaEntered(Area2D area)
	{

	}
	public override void _PhysicsProcess(double delta)
	{
		if (attackTimer > 0)
		{
			attackTimer -= (float)delta;
		}

		// --- LỚP BẢO VỆ 1: NẾU ĐÃ LỠ BỊ TRÔI RA NGOÀI, KÉO VỀ NGAY LẬP TỨC ---
		if (patrolPolygon != null && cachedPolygonPoints != null)
		{
			if (!IsPointInsidePolygon(GlobalPosition))
			{
				targetPlayer = null;
				isAttacking = false;
				isWaitingAtPatrolPoint = false;

				currentPatrolTarget = patrolPolygon.GlobalPosition;
				Vector2 emergencyDir = (currentPatrolTarget - GlobalPosition).Normalized();
				Velocity = emergencyDir * MoveSpeed;
				MoveAndSlide();
				return;
			}
		}

		// --- TỰ ĐỘNG NHẬN DIỆN LẠI PLAYER KHI QUAY TRỞ LẠI VÙNG TUẦN TRA & AGGRO ---
		if (targetPlayer == null)
		{
			var playerNode = GetTree().GetFirstNodeInGroup("Player") as Node2D;
			if (playerNode != null && IsPointInsidePolygon(playerNode.GlobalPosition))
			{
				var aggroArea = GetNodeOrNull<Area2D>("AggroArea");
				if (aggroArea != null && aggroArea.GetOverlappingBodies().Contains(playerNode))
				{
					targetPlayer = playerNode;
					isWaitingAtPatrolPoint = false;
					//GD.Print($"{EnemyName} re-spotted the player inside the patrol area, chasing!");
				}
			}
		}

		// Kiểm tra xem mục tiêu hiện tại có còn nằm trong vùng tuần tra không
		if (targetPlayer != null && !IsPointInsidePolygon(targetPlayer.GlobalPosition))
		{
			targetPlayer = null;
			isAttacking = false;
			isWaitingAtPatrolPoint = false;
			Velocity = Vector2.Zero;
			//GD.Print($"{EnemyName}: Player left the patrol boundary. Ignoring and returning to patrol.");
		}

		// --- TRẠNG THÁI 1: RƯỢT ĐUỔI PLAYER (CÓ CHẶN DỰ BÁO BIÊN GIỚI) ---
		if (targetPlayer != null && !isAttacking)
		{
			Vector2 desiredDir = (targetPlayer.GlobalPosition - GlobalPosition).Normalized();
			Vector2 nextPos = GlobalPosition + desiredDir * MoveSpeed * (float)delta;

			// KIỂM TRA: Nếu tiến bước tiếp theo mà vượt ra ngoài biên giới Polygon -> Chặn lại
			if (IsPointInsidePolygon(nextPos))
			{
				Velocity = desiredDir * MoveSpeed;
				lastFacingDirection = desiredDir;
				PlayAnimation("Walk", desiredDir);
			}
			else
			{
				Velocity = Vector2.Zero;
				PlayAnimation("Stand", lastFacingDirection);
			}

			MoveAndSlide();
		}
		// --- TRẠNG THÁI 2: TẤN CÔNG PLAYER ---
		else if (isAttacking)
		{
			Velocity = Vector2.Zero;

			if (targetPlayer != null)
			{
				Vector2 attackDir = (targetPlayer.GlobalPosition - GlobalPosition).Normalized();
				lastFacingDirection = attackDir;

				PlayAnimation("Attack", attackDir);
				TryAttack();
			}
		}
		// --- TRẠNG THÁI 3: TUẦN TRA NGẪU NHIÊN TRONG VÙNG ĐA GIÁC ---
		else
		{
			if (isWaitingAtPatrolPoint)
			{
				Velocity = Vector2.Zero;
				PlayAnimation("Stand", lastFacingDirection);

				patrolWaitTimer -= (float)delta;
				if (patrolWaitTimer <= 0)
				{
					currentPatrolTarget = GetRandomPointInPatrolArea();
					isWaitingAtPatrolPoint = false;
				}
				return;
			}

			float distanceToTarget = GlobalPosition.DistanceTo(currentPatrolTarget);

			if (distanceToTarget > 10f)
			{
				Vector2 direction = (currentPatrolTarget - GlobalPosition).Normalized();
				Vector2 nextPos = GlobalPosition + direction * (MoveSpeed * 0.5f) * (float)delta;

				// Kiểm tra biên giới cho cả trạng thái tuần tra
				if (IsPointInsidePolygon(nextPos))
				{
					Velocity = direction * (MoveSpeed * 0.5f); // Đi bộ thong thả
					lastFacingDirection = direction;

					PlayAnimation("Walk", direction);
					MoveAndSlide();
				}
				else
				{
					currentPatrolTarget = GetRandomPointInPatrolArea();
				}

				if (GetSlideCollisionCount() > 0 && Velocity.Length() < 2f)
				{
					currentPatrolTarget = GetRandomPointInPatrolArea();
				}
			}
			else
			{
				Velocity = Vector2.Zero;
				isWaitingAtPatrolPoint = true;
				patrolWaitTimer = (float)GD.RandRange(1.5f, 3.0f);
			}
		}
	}

	private void SetupPatrolArea()
	{
		if (!PatrolAreaPath.IsEmpty)
		{
			patrolArea = GetNodeOrNull<Area2D>(PatrolAreaPath);
			if (patrolArea != null)
			{
				patrolPolygon = patrolArea.GetNodeOrNull<CollisionPolygon2D>("CollisionPolygon2D");
				if (patrolPolygon != null && patrolPolygon.Polygon.Length > 0)
				{
					cachedPolygonPoints = patrolPolygon.Polygon;
				}
			}
		}
	}

	protected bool IsPointInsidePolygon(Vector2 globalPoint)
	{
		if (patrolPolygon == null || cachedPolygonPoints == null || cachedPolygonPoints.Length == 0) return true;
		Vector2 localPoint = patrolPolygon.ToLocal(globalPoint);
		return Geometry2D.IsPointInPolygon(localPoint, cachedPolygonPoints);
	}

	protected Vector2 GetRandomPointInPatrolArea()
	{
		if (patrolPolygon == null || cachedPolygonPoints == null || cachedPolygonPoints.Length == 0)
		{
			float randAngle = (float)GD.RandRange(0, Mathf.Pi * 2);
			float randDist = (float)GD.RandRange(40f, 100f);
			return GlobalPosition + new Vector2(Mathf.Cos(randAngle), Mathf.Sin(randAngle)) * randDist;
		}

		float minX = cachedPolygonPoints[0].X, maxX = cachedPolygonPoints[0].X;
		float minY = cachedPolygonPoints[0].Y, maxY = cachedPolygonPoints[0].Y;

		foreach (var pt in cachedPolygonPoints)
		{
			if (pt.X < minX) minX = pt.X;
			if (pt.X > maxX) maxX = pt.X;
			if (pt.Y < minY) minY = pt.Y;
			if (pt.Y > maxY) maxY = pt.Y;
		}

		for (int i = 0; i < 30; i++)
		{
			float randomX = (float)GD.RandRange(minX, maxX);
			float randomY = (float)GD.RandRange(minY, maxY);
			Vector2 localPoint = new Vector2(randomX, randomY);

			if (Geometry2D.IsPointInPolygon(localPoint, cachedPolygonPoints))
			{
				return patrolPolygon.ToGlobal(localPoint);
			}
		}

		return patrolPolygon.GlobalPosition;
	}

	protected virtual void OnAggroBodyEntered(Node2D body)
	{
		if (body.IsInGroup("Player"))
		{
			if (IsPointInsidePolygon(body.GlobalPosition))
			{
				targetPlayer = body;
				isWaitingAtPatrolPoint = false;
				//GD.Print($"{EnemyName} spotted the player inside the patrol area, chasing!");
			}
		}
	}

	protected virtual void OnAggroBodyExited(Node2D body)
	{
		if (body == targetPlayer)
		{
			targetPlayer = null;
			isAttacking = false;
			isWaitingAtPatrolPoint = false;
			Velocity = Vector2.Zero;

			if (patrolPolygon != null)
			{
				currentPatrolTarget = patrolPolygon.GlobalPosition;
			}

			//GD.Print($"{EnemyName} lost player, returning to patrol area.");
		}
	}

	protected virtual void OnAttackAreaBodyEntered(Node2D body)
	{
		if (body.IsInGroup("Player") && body == targetPlayer)
		{
			isAttacking = true;
		}
	}

	protected virtual void OnAttackAreaBodyExited(Node2D body)
	{
		if (body == targetPlayer)
		{
			isAttacking = false;
		}
	}

	protected virtual void TryAttack()
	{
		if (attackTimer <= 0)
		{
			//GD.Print($"{EnemyName} attacks player for {Damage} damage!");
			if (targetPlayer != null)
			{
				targetPlayer.Call("TruMau", Damage);
			}
			attackTimer = AttackCooldown;
		}
	}

	public virtual void TakeDamage(float amount)
	{
		currentHealth = Mathf.Clamp(currentHealth - amount, 0, MaxHealth);
		UpdateHealthBar();

		//GD.Print($"{EnemyName} took {amount} damage. HP left: {currentHealth}");

		if (currentHealth <= 0)
		{
			Die();
		}
	}

	protected virtual void Die()
	{
		string scenePath = SceneFilePath;
		var spawner = GetNodeOrNull<EnemySpawner>("/root/EnemySpawner");
		GD.Print($"Enemy chết! ScenePath: {scenePath} | MaxRespawnCount hiện tại: {maxRespawnCount}");
		// Chỉ gọi respawn nếu số lần spawn còn lại > 0
		if (spawner != null && !string.IsNullOrEmpty(scenePath))
		{
			spawner.RegisterDeadEnemy(scenePath, GlobalPosition, respawnTime, maxRespawnCount);
		}

		QueueFree();
	}

	protected void UpdateHealthBar()
	{
		if (healthBar != null)
		{
			healthBar.MaxValue = 100f;
			float healthPercent = (currentHealth / MaxHealth) * 100f;
			healthBar.Value = healthPercent;
		}
	}

	protected string GetDirectionSuffix(Vector2 direction)
	{
		if (direction == Vector2.Zero) return "Down";

		float deg = Mathf.RadToDeg(direction.Angle());

		if (deg >= -22.5f && deg < 22.5f) return "Right";
		if (deg >= 22.5f && deg < 67.5f) return "Down_Right";
		if (deg >= 67.5f && deg < 112.5f) return "Down";
		if (deg >= 112.5f && deg < 157.5f) return "Down_Left";
		if (deg >= 157.5f || deg < -157.5f) return "Left";
		if (deg >= -157.5f && deg < -112.5f) return "Up_Left";
		if (deg >= -112.5f && deg < -67.5f) return "Up";
		if (deg >= -67.5f && deg < -22.5f) return "Up_Right";

		return "Down";
	}

	protected void PlayAnimation(string state, Vector2 direction)
	{
		if (animSprite == null) return;

		string suffix = GetDirectionSuffix(direction);
		string animName = $"{state}_{suffix}";

		if (animSprite.SpriteFrames.HasAnimation(animName))
		{
			if (animSprite.Animation != animName)
			{
				animSprite.Play(animName);
			}
		}
		else
		{
			string fallbackAnim = $"{state}_Down";
			if (animSprite.SpriteFrames.HasAnimation(fallbackAnim))
			{
				animSprite.Play(fallbackAnim);
			}
		}
	}
}