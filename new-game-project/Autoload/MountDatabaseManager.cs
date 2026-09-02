using Godot;
using Godot.Collections;

public partial class MountDatabaseManager : Node
{
	private Dictionary<string, MountData> mountDatabase = new Dictionary<string, MountData>();

	public override void _Ready()
	{
		LoadAllMounts();
	}

	private void LoadAllMounts()
	{
		LoadMountsRecursive("res://Toa_Ky/");
		GD.Print($"[MountDatabaseManager] Đã tải thông tin {mountDatabase.Count} tọa kỵ (nhẹ, không ngốn RAM PNG).");
	}

	private void LoadMountsRecursive(string path)
	{
		var dir = DirAccess.Open(path);
		if (dir != null)
		{
			dir.ListDirBegin();
			string fileName = dir.GetNext();
			while (fileName != "")
			{
				if (dir.CurrentIsDir())
				{
					if (fileName != "." && fileName != "..")
					{
						LoadMountsRecursive(path + fileName + "/");
					}
				}
				else if (fileName.EndsWith(".tres"))
				{
					string fullPath = path + fileName;
					var mountData = GD.Load<MountData>(fullPath);
					if (mountData != null && !string.IsNullOrEmpty(mountData.MountId))
					{
						if (!mountDatabase.ContainsKey(mountData.MountId))
						{
							mountDatabase.Add(mountData.MountId, mountData);
						}
					}
				}
				fileName = dir.GetNext();
			}
		}
	}

	public MountData GetMountData(string mountId)
	{
		if (mountDatabase.TryGetValue(mountId, out MountData data))
		{
			return data;
		}
		GD.PrintErr("[MountDatabaseManager] Không tìm thấy dữ liệu cho MountId: ", mountId);
		return null;
	}
}