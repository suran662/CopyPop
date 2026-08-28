#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN

#include <shellapi.h>
#include <windows.h>

#include <algorithm>
#include <cwctype>
#include <string>
#include <vector>

namespace {

constexpr UINT WM_TRAY = WM_APP + 1;
constexpr UINT ID_TRAY_EXIT = 1001;
constexpr int kToastWidth = 420;
constexpr int kToastHeight = 56;
constexpr int kPreviewLimit = 54;
constexpr int kMaxPreviewChars = 4096;
constexpr UINT_PTR kHideTimer = 1;
constexpr UINT kToastVisibleMs = 650;

HWND g_mainWindow = nullptr;
HWND g_toastWindow = nullptr;
std::wstring g_message = L"已复制";
NOTIFYICONDATAW g_tray = {};

std::wstring CollapseWhitespace(const std::wstring& text) {
    std::wstring out;
    out.reserve(std::min<int>(static_cast<int>(text.size()), kMaxPreviewChars));
    bool pendingSpace = false;

    for (wchar_t ch : text) {
        if (iswspace(ch)) {
            pendingSpace = !out.empty();
            continue;
        }
        if (pendingSpace) {
            out.push_back(L' ');
            pendingSpace = false;
        }
        out.push_back(ch);
        if (static_cast<int>(out.size()) >= kMaxPreviewChars) {
            break;
        }
    }
    return out;
}

std::wstring Truncate(const std::wstring& text) {
    if (static_cast<int>(text.size()) <= kPreviewLimit) {
        return text;
    }
    return text.substr(0, kPreviewLimit) + L"...";
}

std::wstring TextNotice(const std::wstring& text) {
    const std::wstring cleaned = CollapseWhitespace(text);
    if (cleaned.empty()) {
        return L"";
    }
    return L"已复制：" + Truncate(cleaned);
}

std::wstring FileNameFromPath(const std::wstring& path) {
    const size_t pos = path.find_last_of(L"\\/");
    if (pos == std::wstring::npos || pos + 1 >= path.size()) {
        return path.empty() ? L"文件" : path;
    }
    return path.substr(pos + 1);
}

std::wstring FileNotice(HDROP drop) {
    if (!drop) {
        return L"";
    }

    const UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
    if (count == 0) {
        return L"";
    }
    if (count > 1) {
        return L"已复制 " + std::to_wstring(count) + L" 个文件";
    }

    const UINT len = DragQueryFileW(drop, 0, nullptr, 0);
    if (len == 0) {
        return L"已复制文件";
    }

    std::vector<wchar_t> buffer(len + 1);
    DragQueryFileW(drop, 0, buffer.data(), static_cast<UINT>(buffer.size()));
    return L"已复制文件：" + Truncate(FileNameFromPath(buffer.data()));
}

std::wstring ClipboardText() {
    HANDLE handle = GetClipboardData(CF_UNICODETEXT);
    if (!handle) {
        return L"";
    }

    const wchar_t* text = static_cast<const wchar_t*>(GlobalLock(handle));
    if (!text) {
        return L"";
    }

    int len = 0;
    while (len < kMaxPreviewChars && text[len] != L'\0') {
        ++len;
    }
    std::wstring result(text, text + len);
    GlobalUnlock(handle);
    return result;
}

bool HasImage() {
    static const UINT png = RegisterClipboardFormatW(L"PNG");
    return IsClipboardFormatAvailable(CF_DIB) ||
           IsClipboardFormatAvailable(CF_DIBV5) ||
           IsClipboardFormatAvailable(CF_BITMAP) ||
           (png != 0 && IsClipboardFormatAvailable(png));
}

std::wstring ClipboardNotice() {
    if (!OpenClipboard(g_mainWindow)) {
        return L"已复制内容";
    }

    std::wstring message;

    if (IsClipboardFormatAvailable(CF_HDROP)) {
        message = FileNotice(static_cast<HDROP>(GetClipboardData(CF_HDROP)));
    }

    if (message.empty() && HasImage()) {
        message = L"已复制图片";
    }

    if (message.empty() && IsClipboardFormatAvailable(CF_UNICODETEXT)) {
        message = TextNotice(ClipboardText());
    }

    CloseClipboard();
    return message.empty() ? L"已复制内容" : message;
}

void PositionToastNearCursor(HWND hwnd) {
    POINT cursor;
    GetCursorPos(&cursor);

    MONITORINFO monitor = {};
    monitor.cbSize = sizeof(monitor);
    HMONITOR handle = MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
    GetMonitorInfoW(handle, &monitor);
    const RECT work = monitor.rcWork;

    constexpr int offset = 16;
    constexpr int margin = 10;
    int x = cursor.x + offset;
    int y = cursor.y + offset;

    if (x + kToastWidth > work.right - margin) {
        x = cursor.x - kToastWidth - offset;
    }
    if (y + kToastHeight > work.bottom - margin) {
        y = cursor.y - kToastHeight - offset;
    }

    x = std::clamp(x, work.left + margin, work.right - kToastWidth - margin);
    y = std::clamp(y, work.top + margin, work.bottom - kToastHeight - margin);

    SetWindowPos(
        hwnd,
        HWND_TOPMOST,
        x,
        y,
        kToastWidth,
        kToastHeight,
        SWP_NOACTIVATE | SWP_SHOWWINDOW
    );
}

void ShowToast(const std::wstring& message) {
    if (!g_toastWindow) {
        return;
    }
    g_message = message;
    PositionToastNearCursor(g_toastWindow);
    InvalidateRect(g_toastWindow, nullptr, TRUE);
    SetTimer(g_toastWindow, kHideTimer, kToastVisibleMs, nullptr);
}

void AddTrayIcon(HWND hwnd) {
    g_tray = {};
    g_tray.cbSize = sizeof(g_tray);
    g_tray.hWnd = hwnd;
    g_tray.uID = 1;
    g_tray.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    g_tray.uCallbackMessage = WM_TRAY;
    g_tray.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
    lstrcpynW(g_tray.szTip, L"CopyPop", ARRAYSIZE(g_tray.szTip));
    Shell_NotifyIconW(NIM_ADD, &g_tray);
}

void RemoveTrayIcon() {
    if (g_tray.cbSize != 0) {
        Shell_NotifyIconW(NIM_DELETE, &g_tray);
    }
}

void ShowTrayMenu(HWND hwnd) {
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, ID_TRAY_EXIT, L"退出 CopyPop");

    POINT cursor;
    GetCursorPos(&cursor);
    SetForegroundWindow(hwnd);
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, cursor.x, cursor.y, 0, hwnd, nullptr);
    DestroyMenu(menu);
}

HFONT UiFont(int size, int weight) {
    return CreateFontW(
        -size,
        0,
        0,
        0,
        weight,
        FALSE,
        FALSE,
        FALSE,
        DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_SWISS,
        L"Segoe UI"
    );
}

LRESULT CALLBACK ToastProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
    switch (message) {
    case WM_CREATE: {
        HRGN region = CreateRoundRectRgn(0, 0, kToastWidth + 1, kToastHeight + 1, 28, 28);
        SetWindowRgn(hwnd, region, TRUE);
        SetLayeredWindowAttributes(hwnd, 0, 235, LWA_ALPHA);
        return 0;
    }
    case WM_TIMER:
        if (wparam == kHideTimer) {
            KillTimer(hwnd, kHideTimer);
            ShowWindow(hwnd, SW_HIDE);
        }
        return 0;
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC dc = BeginPaint(hwnd, &ps);
        RECT rect;
        GetClientRect(hwnd, &rect);

        HBRUSH background = CreateSolidBrush(RGB(28, 28, 30));
        HBRUSH checkBrush = CreateSolidBrush(RGB(98, 217, 139));
        HPEN border = CreatePen(PS_SOLID, 1, RGB(62, 62, 66));
        HGDIOBJ oldBrush = SelectObject(dc, background);
        HGDIOBJ oldPen = SelectObject(dc, border);
        RoundRect(dc, rect.left, rect.top, rect.right, rect.bottom, 28, 28);

        RECT circle = {12, 17, 34, 39};
        SelectObject(dc, checkBrush);
        SelectObject(dc, GetStockObject(NULL_PEN));
        Ellipse(dc, circle.left, circle.top, circle.right, circle.bottom);

        SetBkMode(dc, TRANSPARENT);
        SetTextColor(dc, RGB(8, 45, 24));
        HFONT checkFont = UiFont(16, FW_BOLD);
        HGDIOBJ oldFont = SelectObject(dc, checkFont);
        DrawTextW(dc, L"\u2713", -1, &circle, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

        SetTextColor(dc, RGB(245, 245, 247));
        HFONT textFont = UiFont(15, FW_MEDIUM);
        SelectObject(dc, textFont);
        RECT textRect = {43, 0, kToastWidth - 14, kToastHeight};
        DrawTextW(dc, g_message.c_str(), -1, &textRect, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS);

        SelectObject(dc, oldFont);
        SelectObject(dc, oldBrush);
        SelectObject(dc, oldPen);
        DeleteObject(checkFont);
        DeleteObject(textFont);
        DeleteObject(background);
        DeleteObject(checkBrush);
        DeleteObject(border);
        EndPaint(hwnd, &ps);
        return 0;
    }
    default:
        return DefWindowProcW(hwnd, message, wparam, lparam);
    }
}

LRESULT CALLBACK MainProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
    switch (message) {
    case WM_CREATE:
        AddClipboardFormatListener(hwnd);
        AddTrayIcon(hwnd);
        return 0;
    case WM_CLIPBOARDUPDATE:
        ShowToast(ClipboardNotice());
        return 0;
    case WM_TRAY:
        if (lparam == WM_RBUTTONUP || lparam == WM_LBUTTONUP) {
            ShowTrayMenu(hwnd);
        }
        return 0;
    case WM_COMMAND:
        if (LOWORD(wparam) == ID_TRAY_EXIT) {
            DestroyWindow(hwnd);
        }
        return 0;
    case WM_DESTROY:
        RemoveClipboardFormatListener(hwnd);
        RemoveTrayIcon();
        PostQuitMessage(0);
        return 0;
    default:
        return DefWindowProcW(hwnd, message, wparam, lparam);
    }
}

}  // namespace

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int) {
    const wchar_t mainClass[] = L"CopyPopMainWindow";
    const wchar_t toastClass[] = L"CopyPopToastWindow";

    WNDCLASSW mainWindowClass = {};
    mainWindowClass.lpfnWndProc = MainProc;
    mainWindowClass.hInstance = instance;
    mainWindowClass.lpszClassName = mainClass;
    RegisterClassW(&mainWindowClass);

    WNDCLASSW toastWindowClass = {};
    toastWindowClass.lpfnWndProc = ToastProc;
    toastWindowClass.hInstance = instance;
    toastWindowClass.lpszClassName = toastClass;
    toastWindowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    RegisterClassW(&toastWindowClass);

    g_mainWindow = CreateWindowExW(
        0,
        mainClass,
        L"CopyPop",
        WS_OVERLAPPED,
        0,
        0,
        0,
        0,
        nullptr,
        nullptr,
        instance,
        nullptr
    );

    g_toastWindow = CreateWindowExW(
        WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TRANSPARENT,
        toastClass,
        L"CopyPop",
        WS_POPUP,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        kToastWidth,
        kToastHeight,
        nullptr,
        nullptr,
        instance,
        nullptr
    );

    if (!g_mainWindow || !g_toastWindow) {
        return 1;
    }

    MSG message;
    while (GetMessageW(&message, nullptr, 0, 0) > 0) {
        TranslateMessage(&message);
        DispatchMessageW(&message);
    }
    return 0;
}
