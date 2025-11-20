<#-------------------------------------------------------------------------------

    Arcane :: Server

    .Developer
        Jean-Pierre LESUEUR (@DarkCoderSc)
        https://www.twitter.com/darkcodersc
        https://www.github.com/PhrozenIO
        https://github.com/DarkCoderSc
        www.phrozen.io
        jplesueur@phrozen.io
        PHROZEN

    .License
        Apache License
        Version 2.0, January 2004
        http://www.apache.org/licenses/

    .Disclaimer
        This script is provided "as is", without warranty of any kind, express or
        implied, including but not limited to the warranties of merchantability,
        fitness for a particular purpose and noninfringement. In no event shall the
        authors or copyright holders be liable for any claim, damages or other
        liability, whether in an action of contract, tort or otherwise, arising
        from, out of or in connection with the software or the use or other dealings
        in the software.

    .Notice
        Writing the entire code in a single PowerShell script is wished,
        allowing it to function both as a module or a standalone script.

-------------------------------------------------------------------------------#>

# ----------------------------------------------------------------------------- #
#                                                                               #
#                                                                               #
#                                                                               #
#  Global Variables                                                             #
#                                                                               #
#                                                                               #
#                                                                               #
# ----------------------------------------------------------------------------- #

$global:ArcaneVersion = "1.0.5"
$global:ArcaneProtocolVersion = "5.0.2"

$global:HostSyncHash = [HashTable]::Synchronized(@{
    host = $host
    ClipboardText = (Get-Clipboard -Raw)
})

# ----------------------------------------------------------------------------- #
#                                                                               #
#                                                                               #
#                                                                               #
#  Enums Definitions                                                            #
#                                                                               #
#                                                                               #
#                                                                               #
# ----------------------------------------------------------------------------- #

enum ClipboardMode {
    Disabled = 1
    Receive = 2
    Send = 3
    Both = 4
}

enum ProtocolCommand {
    Success = 1
    Fail = 2
    RequestSession = 3
    AttachToSession = 4
    BadRequest = 5
    ResourceFound = 6
    ResourceNotFound = 7
}

enum WorkerKind {
    Desktop = 1
    Events = 2
}

enum LogKind {
    Information
    Warning
    Success
    Error
}

# ----------------------------------------------------------------------------- #
#                                                                               #
#                                                                               #
#                                                                               #
#  Windows API Definitions                                                      #
#                                                                               #
#                                                                               #
#                                                                               #
# ----------------------------------------------------------------------------- #

Add-Type -Assembly System.Windows.Forms

Add-Type @"
    using System;
    using System.Security;
    using System.Runtime.InteropServices;

    public static class User32
    {
        [DllImport("user32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool OpenClipboard(IntPtr hWndNewOwner);

        [DllImport("user32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseClipboard();

        [DllImport("user32.dll", SetLastError=true)]
        public static extern IntPtr SetClipboardData(uint uFormat, IntPtr hMem);

        [DllImport("user32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EmptyClipboard();

        [DllImport("User32.dll", SetLastError=false)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetProcessDPIAware();

        [DllImport("User32.dll", SetLastError=false)]
        [return: MarshalAs(UnmanagedType.U4)]
        public static extern uint LoadCursorA(int hInstance, int lpCursorName);

        [DllImport("User32.dll", SetLastError=false)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetCursorInfo(IntPtr pci);

        [DllImport("user32.dll", SetLastError=false)]
        public static extern void mouse_event(int flags, int dx, int dy, int cButtons, int info);

        [DllImport("user32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.U4)]
        public static extern int GetSystemMetrics(int nIndex);

        [DllImport("User32.dll", SetLastError=false)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ReleaseDC(IntPtr hWnd, IntPtr hDC);

        [DllImport("user32.dll", SetLastError=false)]
        public static extern IntPtr GetDC(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError=true)]
        public static extern IntPtr OpenInputDesktop(
            uint dwFlags,
            bool fInherit,
            uint dwDesiredAccess
        );

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool LockWorkStation();

        [DllImport("user32.dll", SetLastError=true, CharSet = CharSet.Unicode)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetUserObjectInformation(
            IntPtr hObj,
            int nIndex,
            IntPtr pvInfo,
            uint nLength,
            ref uint lpnLengthNeeded
        );

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseDesktop(
            IntPtr hDesktop
        );

        [DllImport("user32.dll", SetLastError=true)]
        public static extern IntPtr GetThreadDesktop(uint dwThreadId);

        [DllImport("user32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetThreadDesktop(
            IntPtr hDesktop
        );

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.U4)]
        public static extern uint SendInput(
            uint nInputs,
            IntPtr pInputs,
            int cbSize
        );
    }

    public static class Kernel32
    {
        [DllImport("kernel32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GlobalUnlock(IntPtr hMem);

        [DllImport("Kernel32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.U4)]
        public static extern uint SetThreadExecutionState(uint esFlags);

        [DllImport("kernel32.dll", SetLastError=false, EntryPoint="RtlMoveMemory"), SuppressUnmanagedCodeSecurity]
        public static extern void CopyMemory(
            IntPtr dest,
            IntPtr src,
            IntPtr count
        );

        [DllImport("kernel32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.U4)]
        public static extern uint GetCurrentThreadId();

        [DllImport("kernel32.dll", SetLastError=true, CharSet = CharSet.Unicode)]
        public static extern IntPtr LoadLibrary(string lpFileName);

        [DllImport("kernel32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool FreeLibrary(IntPtr hModule);

        [DllImport("kernel32.dll", SetLastError=true, CharSet = CharSet.Ansi)]
        public static extern IntPtr GetProcAddress(
            IntPtr hModule,
            string procName
        );
    }

    public static class MSVCRT
    {
        [DllImport("msvcrt.dll", SetLastError=false, CallingConvention=CallingConvention.Cdecl), SuppressUnmanagedCodeSecurity]
        public static extern IntPtr memcmp(
            IntPtr p1,
            IntPtr p2,
            IntPtr count
        );
    }

    public static class GDI32
    {
        [DllImport("gdi32.dll")]
        public static extern IntPtr DeleteDC(IntPtr hDc);

        [DllImport("gdi32.dll")]
        public static extern IntPtr DeleteObject(IntPtr hDc);

        [DllImport("gdi32.dll", SetLastError=false), SuppressUnmanagedCodeSecurity]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool BitBlt(
            IntPtr hdcDest,
            int xDest,
            int yDest,
            int wDest,
            int hDest,
            IntPtr hdcSource,
            int xSrc,
            int ySrc,
            int RasterOp
        );

        [DllImport("gdi32.dll", SetLastError=false)]
        public static extern IntPtr CreateDIBSection(
            IntPtr hdc,
            IntPtr pbmi,
            uint usage,
            out IntPtr ppvBits,
            IntPtr hSection,
            uint offset
        );

        [DllImport ("gdi32.dll")]
        public static extern IntPtr CreateCompatibleBitmap(
            IntPtr hdc,
            int nWidth,
            int nHeight
        );

        [DllImport ("gdi32.dll")]
        public static extern IntPtr CreateCompatibleDC(IntPtr hdc);

        [DllImport ("gdi32.dll")]
        public static extern IntPtr SelectObject(IntPtr hdc, IntPtr bmp);

        [DllImport ("gdi32.dll")]
        [return: MarshalAs(UnmanagedType.U4)]
        public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
    }

    public static class Shcore {
        [DllImport("Shcore.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.U4)]
        public static extern uint SetProcessDpiAwareness(uint value);
    }
"@

# ----------------------------------------------------------------------------- #
#                                                                               #
#                                                                               #
#                                                                               #
#  Script Blocks                                                                #
#                                                                               #
#                                                                               #
#                                                                               #
# ----------------------------------------------------------------------------- #

$global:WinAPI_Const_ScriptBlock = {
    $GENERIC_ALL = 0x10000000
}

# -------------------------------------------------------------------------------

$global:WinAPIException_Class_ScriptBlock = {
    class WinAPIException: System.Exception
    {
        WinAPIException([string] $ApiName) : base (
            [string]::Format(
                "WinApi Exception -> {0}, LastError: {1}",
                $ApiName,
                [System.Runtime.InteropServices.Marshal]::GetLastWin32Error().ToString()
            )
        )
        {}
        $ErrorActionPreference = $oldErrorActionPreference
        $VerbosePreference = $oldVerbosePreference
    }
}

# -------------------------------------------------------------------------------

try {
    Export-ModuleMember -Function Invoke-ArcaneServer
} catch {}