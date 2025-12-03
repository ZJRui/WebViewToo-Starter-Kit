#Requires AutoHotkey v2.0
#Include ./JSON.ahk
#SingleInstance Force


; ==============================================================================
; Receiver.ahk - 监听并处理自定义Windows消息
; ==============================================================================

; 1. 定义一个唯一的窗口标题，以便发送方可以找到我们。
global MyWinTitle := "MyUniqueMessageReceiverWindow"

; 2. 定义自定义消息编号。
;    必须大于等于 0x400 (WM_USER)。选择一个不常用的高数值可以避免冲突。
global MY_CUSTOM_MESSAGE := 0x5555

; 3. 创建一个GUI窗口。OnMessage需要一个GUI线程来附加。
;    这个窗口可以是隐藏的，但为了演示，我们让它可见。
MyGui := Gui(, MyWinTitle)
MyGui.SetFont("s10", "Segoe UI")
MyGui.Add("Text", "w300", "我正在等待消息... (消息ID: " MY_CUSTOM_MESSAGE ")")
MyGui.Add("Text", "w300 cGray", "请运行 Sender.ahk 来发送指令。")
MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w350")

; 4. 使用 OnMessage 注册回调函数。
;    当接收到 MY_CUSTOM_MESSAGE (0x5555) 消息时，会自动调用 HandleMyMessage 函数。
OnMessage(MY_CUSTOM_MESSAGE, HandleMyMessage)

; 5. 定义回调函数 (消息处理器)
;    函数签名: Callback(wParam, lParam, Msg, Hwnd)
HandleMyMessage(wParam, lParam, msg, hwnd) {
    OutputDebug("wParam: " wParam " lParam:" lParam "msgId:" msg "hwnd:" hwnd)
    showSenderWindowControlInfo(hwnd)
    ; wParam 和 lParam 是由发送方传递过来的数据。
    ; msg 是消息的编号 (在这里就是 0x5555)。
    ; hwnd 是接收消息的窗口句柄。


    ; 根据 wParam 的值来执行不同的操作
    if (wParam = 1) {
        ; 命令 1: 显示一个 MsgBox
        ; lParam 在这里被用作要显示的消息内容。
        ; 注意：在v2中，lParam 可能是整数或指针。如果发送的是字符串，
        ; 需要用 StrGet() 从其内存地址读取。
        receivedText := StrGet(lParam)

        OutputDebug("wParam: " wParam " lParam:" lParam "msg:" msg "hwnd:" hwnd ",receivedText:" receivedText)

        ; MsgBox "接收到命令 1！`n内容: " receivedText, "来自 Receiver", "Iconi"

        ; 返回一个值给 SendMessage 的调用方
        return "MsgBox 命令已处理"

    } else if (wParam = 2) {
        ; 命令 2: 显示一个 ToolTip
        ; lParam 在这里被用作要显示的 ToolTip 持续时间（毫秒）。
        receivedText := StrGet(lParam)
        OutputDebug("wParam: " wParam " lParam:" lParam "msg:" msg "hwnd:" hwnd ",receivedText:" receivedText)
        ; ToolTip receivedText, , , 1
        ; SetTimer () => ToolTip(), -3000 ; 3秒后清除 ToolTip

        ; 返回一个值
        return "ToolTip 命令已处理"

    } else {
        MsgBox "接收到未知命令！`nwParam: " wParam "`nlParam: " lParam, "来自 Receiver", "Icon!"
        return "未知命令"
    }
}


showSenderWindowControlInfo(hwnd)
{
    ; 1. 获取该句柄的类名 (例如 Button, Edit, AutoHotkeyGUI)
    class := WinGetClass("ahk_id " hwnd)

    ; 2. 获取该句柄的文本/标题 (例如 "确定", "请输入")
    try {
        text := ControlGetText("ahk_id " hwnd)
    } catch as error {
        OutputDebug error.Message
        text := WinGetTitle("ahk_id " hwnd)
    }

    ; 3. 获取它的父窗口标题 (看看它属于哪个软件)
    parentTitle := ""
    try {
        ; 获取父窗口句柄
        parentHwnd := DllCall("GetParent", "Ptr", hwnd, "Ptr")
        if (parentHwnd)
            parentTitle := WinGetTitle("ahk_id " parentHwnd)
    }

    OutputDebug "【身份侦探】`n"
        . "句柄 (HWND): " hwnd "`n"
        . "控件类型: " class "`n"
        . "控件内容: " text "`n"
        . "所属窗口: " parentTitle
}

OnMessage(0x004A, HandleCopyData2)

HandleCopyData(wParam, lParam, msg, hwnd) {
    dwData := NumGet(lParam + 0, "Ptr")
    cbData := NumGet(lParam + A_PtrSize, "Ptr")
    lpData := NumGet(lParam + A_PtrSize * 2, "Ptr")

    receivedText := StrGet(lpData)
    MsgBox "收到WM_COPYDATA: " receivedText
    return true
}


HandleCopyData2(wParam, lParam, msg, hwnd) {
    OutputDebug("wParam: " wParam " lParam:" lParam "msgId:" msg "hwnd:" hwnd)
    showSenderWindowControlInfo(hwnd)
    ; COPYDATASTRUCT 占用 3 个字段：dwData, cbData, lpData
    ; 所以结构体布局如下：
    ; Offset 0:       dwData   (Ptr)
    ; Offset +A_PtrSize: cbData   (UInt)
    ; Offset +2*A_PtrSize: lpData  (Ptr)

    ; 从 lParam 中读取结构体内容
    dwData := NumGet(lParam + 0, "Ptr")
    cbData := NumGet(lParam + A_PtrSize, "UInt")
    lpData := NumGet(lParam + A_PtrSize * 2, "Ptr")

    ; 安全提取 UTF-16 字符串（最多读取 cbData 字节）
    ; StrGet 会自动以 null 结尾终止读取，但这里我们可以手动限制读取长度：
    charCount := cbData // 2  ; UTF-16：2 字节 = 1 字符
    text := StrGet(lpData, charCount, "UTF-16")

    MsgBox "收到数据:`n`n dwData: " dwData "`n cbData: " cbData "`n 内容: " text, "WM_COPYDATA"

    ; 可以根据 dwData 决定不同的处理逻辑
    if (dwData = 1) {
        ToolTip "收到命令 1: " text
        SetTimer () => ToolTip(), -3000
    }

    return true ; 返回 true 表示消息已处理
}


/**
 * 发送 结构体数据（多个字段）-假设结构体内容如下（我们模拟一个简单的用户数据）：
 * struct UserData {
 *     int id;
 *     double score;
 * }
 */
; OnMessage(0x4A, HandleCopyDataStruct)

HandleCopyDataStruct(wParam, lParam, msg, hwnd) {
    dwData := NumGet(lParam + 0, "Ptr")
    cbData := NumGet(lParam + A_PtrSize, "UInt")
    lpData := NumGet(lParam + A_PtrSize * 2, "Ptr")

    if (dwData = 2001 && cbData = 12) {
        id := NumGet(lpData, 0, "Int")
        score := NumGet(lpData, 4, "Double")
        MsgBox "收到结构体：`nid: " id "`nscore: " score
        return true
    }

    return false
}


/**
 * 发送 JSON 或键值对数据（序列化为文本）
 * 虽然 COPYDATASTRUCT 是可以发送二进制，但发送结构化数据如键值对，更通用的是用 JSON 格式字符串 传输，然后接收端解析它。
 * 
 */
OnMessage(0x4A, HandleJson)

HandleJson(wParam, lParam, msg, hwnd) {
    dwData := NumGet(lParam + 0, "Ptr")
    cbData := NumGet(lParam + A_PtrSize, "UInt")
    lpData := NumGet(lParam + A_PtrSize * 2, "Ptr")

    if (dwData = 3001) {
        json := StrGet(lpData, cbData // 2, "UTF-16")
        data := JSON.Parse(json)
        MsgBox "收到JSON:`n用户: " data["user"] "`n分数: " data["score"]
        return true
    }
    return false
}


/**
 * 接收端处理建议
 * 接收端可用统一方式解析：
 */
OnMessage(0x4A, HandleAnyCopyData)

HandleAnyCopyData(wParam, lParam, msg, hwnd) {

    dwData := NumGet(lParam + 0, "Ptr")
    cbData := NumGet(lParam + A_PtrSize, "UInt")
    lpData := NumGet(lParam + A_PtrSize * 2, "Ptr")

    if (dwData = 2001 && cbData = 12) {
        id := NumGet(lpData, 0, "Int")
        score := NumGet(lpData, 4, "Double")
        MsgBox "结构体：id=" id " score=" score
    }
    else if (dwData = 3001) {
        text := StrGet(lpData, cbData // 2, "UTF-16")
        data := JSON.Parse(text)
        MsgBox "JSON：姓名=" data["user"] "`n年龄=" data["age"]
    }
    else {
        MsgBox "收到未知类型: " dwData
    }

    return true
}