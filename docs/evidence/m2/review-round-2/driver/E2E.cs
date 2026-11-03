using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class E2E {
	[StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
	[DllImport("user32.dll")] static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
	[StructLayout(LayoutKind.Sequential)] public struct LASTINPUTINFO { public uint Size; public uint Time; }
	[DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO i);
	[DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
	[DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
	[DllImport("user32.dll")] static extern int GetKeyboardLayoutList(int n, IntPtr[] l);
	[DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
	[DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
	[DllImport("user32.dll")] static extern IntPtr GetKeyboardLayout(uint t);
	[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();

	[StructLayout(LayoutKind.Sequential)] public struct XINPUT_STATE { public uint Packet; public ushort Buttons; public byte LT, RT; public short LX, LY, RX, RY; }
	[DllImport("xinput1_4.dll", EntryPoint="XInputGetState")] static extern uint XInputGetState(uint i, out XINPUT_STATE s);
	// Read-only: which XInput slots have a controller.
	public static string XInputSlots() {
		var o = new List<string>();
		for (uint i = 0; i < 4; i++) { XINPUT_STATE s; if (XInputGetState(i, out s) == 0) o.Add(i.ToString()); }
		return o.Count == 0 ? "none" : string.Join(",", o);
	}
	public static string Layouts() {
		var l = new IntPtr[32];
		int n = GetKeyboardLayoutList(32, l);
		var o = new List<string>();
		for (int i = 0; i < n; i++) o.Add(l[i].ToInt64().ToString("X8"));
		return string.Join(",", o);
	}
	// The layout the given window's own thread has. Read-only.
	public static string WindowLayout(IntPtr h) {
		uint p;
		return GetKeyboardLayout(GetWindowThreadProcessId(h, out p)).ToInt64().ToString("X8");
	}
	public static string ForegroundLayout() {
		uint p;
		return GetKeyboardLayout(GetWindowThreadProcessId(GetForegroundWindow(), out p)).ToInt64().ToString("X8");
	}
	// Goes to this window only, so a stray key can never reach another application.
	public static void Key(IntPtr h, int vk, int scan, bool down, bool ext) {
		long l = 1 | ((long)scan << 16) | (ext ? 1L << 24 : 0);
		if (!down) l |= (1L << 30) | (1L << 31);
		PostMessageW(h, down ? 0x100u : 0x101u, (IntPtr)vk, (IntPtr)l);
	}
	// When the machine last saw physical input, not what it was. Posted window messages do not count.
	public static long PhysicalIdleMs() {
		var i = new LASTINPUTINFO(); i.Size = (uint)Marshal.SizeOf(i);
		GetLastInputInfo(ref i);
		return (long)(uint)(Environment.TickCount - (int)i.Time);
	}
	public static bool IsForeground(IntPtr h) { return GetForegroundWindow() == h; }
	public static string Client(IntPtr h) { RECT r; GetClientRect(h, out r); return (r.R - r.L) + "x" + (r.B - r.T); }
	public static void Shot(IntPtr h, string path) {
		RECT r; GetClientRect(h, out r);
		using (var b = new Bitmap(Math.Max(1, r.R - r.L), Math.Max(1, r.B - r.T), PixelFormat.Format32bppArgb))
		using (var g = Graphics.FromImage(b)) {
			IntPtr dc = g.GetHdc();
			PrintWindow(h, dc, 3); // Client area, full content, which includes GPU-drawn windows.
			g.ReleaseHdc(dc);
			b.Save(path, ImageFormat.Png);
		}
	}
}
