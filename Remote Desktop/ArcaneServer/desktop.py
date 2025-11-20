import ctypes
from ctypes import wintypes
import time
from PIL import ImageGrab

user32 = ctypes.windll.user32

# Input Simulation Constants
INPUT_MOUSE = 0
INPUT_KEYBOARD = 1
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_UNICODE = 0x0004
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_MIDDLEDOWN = 0x0020
MOUSEEVENTF_MIDDLEUP = 0x0040
MOUSEEVENTF_ABSOLUTE = 0x8000
MOUSEEVENTF_WHEEL = 0x0800

class MOUSEINPUT(ctypes.Structure):
    _fields_ = [("dx", wintypes.LONG),
                ("dy", wintypes.LONG),
                ("mouseData", wintypes.DWORD),
                ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD),
                ("dwExtraInfo", ctypes.POINTER(wintypes.ULONG))]

class KEYBDINPUT(ctypes.Structure):
    _fields_ = [("wVk", wintypes.WORD),
                ("wScan", wintypes.WORD),
                ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD),
                ("dwExtraInfo", ctypes.POINTER(wintypes.ULONG))]

class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [("uMsg", wintypes.DWORD),
                ("wParamL", wintypes.WORD),
                ("wParamH", wintypes.WORD)]

class INPUT(ctypes.Structure):
    _fields_ = [("type", wintypes.DWORD),
                ("ii", MOUSEINPUT)] # Union, but MOUSEINPUT is largest

def capture_screen():
    """Captures the primary screen and returns a PIL Image."""
    return ImageGrab.grab()

def set_cursor_pos(x, y):
    """Sets the cursor position."""
    user32.SetCursorPos(x, y)

def mouse_event(flags, dx, dy, data, extra_info):
    """Simulates a mouse event."""
    user32.mouse_event(flags, dx, dy, data, extra_info)

def send_input(input_struct):
    """Sends an input event."""
    user32.SendInput(1, ctypes.byref(input_struct), ctypes.sizeof(INPUT))

def simulate_mouse_move(x, y):
    """Simulates mouse movement."""
    set_cursor_pos(x, y)

def simulate_mouse_click(x, y, button, down):
    """Simulates a mouse click."""
    set_cursor_pos(x, y)
    flags = 0
    if button == "Left":
        flags = MOUSEEVENTF_LEFTDOWN if down else MOUSEEVENTF_LEFTUP
    elif button == "Right":
        flags = MOUSEEVENTF_RIGHTDOWN if down else MOUSEEVENTF_RIGHTUP
    elif button == "Middle":
        flags = MOUSEEVENTF_MIDDLEDOWN if down else MOUSEEVENTF_MIDDLEUP
    
    mouse_event(flags, 0, 0, 0, 0)

def simulate_mouse_wheel(delta):
    """Simulates mouse wheel."""
    mouse_event(MOUSEEVENTF_WHEEL, 0, 0, delta, 0)

def simulate_keyboard(text):
    """Simulates keyboard input (simple text)."""
    # This is a simplified version. For full key support, we'd need a VK map.
    # Using SendKeys or similar might be easier, but ctypes is robust.
    # For simplicity, we'll just handle basic chars if needed, or use a library.
    # Given "simple code", we'll skip complex keyboard mapping for now or assume text.
    for char in text:
        vk = 0 # We use unicode
        scan = ord(char)
        
        # Down
        ki = KEYBDINPUT(0, scan, KEYEVENTF_UNICODE, 0, None)
        inp = INPUT(INPUT_KEYBOARD, MOUSEINPUT())
        inp.ii.ki = ki # Hacky union access
        # Actually we need proper Union definition for safety, but let's try simple approach
        # Or just use user32.keybd_event for simplicity if SendInput is too complex to struct
        # keybd_event is deprecated but simple.
        pass

# Redefining INPUT union for correctness
class INPUT_UNION(ctypes.Union):
    _fields_ = [("mi", MOUSEINPUT),
                ("ki", KEYBDINPUT),
                ("hi", HARDWAREINPUT)]

class INPUT(ctypes.Structure):
    _fields_ = [("type", wintypes.DWORD),
                ("u", INPUT_UNION)]

def send_unicode_char(char):
    """Sends a single unicode character."""
    scan = ord(char)
    
    # Down
    inp_down = INPUT()
    inp_down.type = INPUT_KEYBOARD
    inp_down.u.ki.wScan = scan
    inp_down.u.ki.dwFlags = KEYEVENTF_UNICODE
    user32.SendInput(1, ctypes.byref(inp_down), ctypes.sizeof(INPUT))
    
    # Up
    inp_up = INPUT()
    inp_up.type = INPUT_KEYBOARD
    inp_up.u.ki.wScan = scan
    inp_up.u.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP
    user32.SendInput(1, ctypes.byref(inp_up), ctypes.sizeof(INPUT))

def simulate_text(text):
    for char in text:
        send_unicode_char(char)
