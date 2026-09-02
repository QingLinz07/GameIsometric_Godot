using Godot;
using Godot.Collections;

public partial class MountDatabaseManager : Node
{
	// Từ điển tra cứu nhanh: Key = MountId, Value = MountData (.tres)
	private Dictionary<string, MountData> mountDatabase = new Dictionary<string, MountData>();

	public override void _Ready()
	{
		// Tự động quét và nạp dữ liệu khi game khởi chạy
		LoadAllMounts();
	}

	private void LoadAllMounts()
	{
		// Ví dụ: Quét toàn bộ thư mục chứa tọa kỵ của bạn
		LoadMountsRecursive("res://Toa_Ky/");
		GD.Print($"[MountDatabaseManager] Đã tải thành công {mountDatabase.Count} tọa kỵ vào bộ nhớ.");
	}

	// Hàm đệ quy tự động tìm kiếm mọi file .tres trong tất cả các thư mục con
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

	// Hàm gọi để lấy thông tin MountData bất kỳ chỉ bằng ID (Bất chấp nằm ở thư mục nào)
	public MountData GetMountData(string mountId)
	{
		if (mountDatabase.ContainsKey(mountId))
		{
			return mountDatabase[mountId];
		}
		GD.PrintErr("[MountDatabaseManager] Không tìm thấy dữ liệu cho MountId: ", mountId);
		return null;
	}
}