using Godot;
using System.Collections.Generic;

public partial class EnemySpawner : Node
{
	private struct EnemySpawnData
	{
		public string ScenePath;
		public Vector2 SpawnPosition;
		public float RespawnTimer;
		public int RemainingSpawns;
	}

	private List<EnemySpawnData> respawnQueue = new List<EnemySpawnData>();

	public override void _Process(double delta)
	{
		for (int i = respawnQueue.Count - 1; i >= 0; i--)
		{
			var data = respawnQueue[i];
			data.RespawnTimer -= (float)delta;

			if (data.RespawnTimer <= 0)
			{
				// Nếu là -1 (vô hạn) hoặc số lượt còn lại > 0 thì cho spawn
				if (data.RemainingSpawns == -1 || data.RemainingSpawns > 0)
				{
					var enemyPackedScene = GD.Load<PackedScene>(data.ScenePath);
					if (enemyPackedScene != null)
					{
						Node2D newEnemy = (Node2D)enemyPackedScene.Instantiate();
						newEnemy.GlobalPosition = data.SpawnPosition;

						if (newEnemy is Enemy enemyScript)
						{
							// Cập nhật số lần spawn còn lại cho con mới:
							// Nếu là -1 thì giữ nguyên -1, nếu > 0 thì trừ đi 1
							enemyScript.maxRespawnCount = (data.RemainingSpawns == -1) ? -1 : data.RemainingSpawns - 1;
						}

						GetTree().CurrentScene.AddChild(newEnemy);
					}
				}

				respawnQueue.RemoveAt(i);
			}
			else
			{
				respawnQueue[i] = data;
			}
		}
	}

	public void RegisterDeadEnemy(string scenePath, Vector2 position, float respawnDelay, int currentSpawns)
	{
		// Nếu đường dẫn trống hoặc số lượt hiện tại đã bằng 0 thì không cho vào hàng đợi nữa
		if (string.IsNullOrEmpty(scenePath) || currentSpawns == 0) return;

		respawnQueue.Add(new EnemySpawnData
		{
			ScenePath = scenePath,
			SpawnPosition = position,
			RespawnTimer = respawnDelay,
			RemainingSpawns = currentSpawns
		});
	}
}