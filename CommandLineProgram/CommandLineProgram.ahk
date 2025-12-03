#Requires AutoHotkey v2
#SingleInstance Force
#Include <JSON\JSON>


#Include ../WebViewToo/Lib/WebViewToo.ahk
/**
 * 如果脚本要在空闲状态下保持运行, 以监测传入的消息, 可能需要调用 Persistent 函数来防止脚本退出. OnMessage 不会自动使脚本持续运行, 因为这有时是不必要的或不需要的. 例如, 当 OnMessage 被用来监视 GUI 窗口的输入时(如在 WM_LBUTTONDOWN 的例子), 通常让脚本在最后一个 GUI 窗口关闭时自动退出更为合适.
 * 
 * 默认情况下，一个 AutoHotkey 脚本会在没有活动内容时自动退出（即主线程没事干时退出）
 * 
 * 所谓“空闲状态下保持运行”指的是：脚本没有热键、没有 GUI、没有计时器或线程，却需要接收消息（如 WM_COPYDATA, WM_USER, 自定义消息等）
 * 
 * 用于告诉脚本：“不要因为没有前台活动就退出！”  这就让脚本处于监听状态，即使它什么都没在做
 * 
 * OnMessage 不会自动使脚本持续运行, 因为这有时是不必要的或不需要的。
 * 
 */
Persistent

BackSpaceHexCode := 0x8
BackSpaceCode := 8
WM_CHAR := 0x102
WM_USER := 0x0400
WM_COPYDATA := 0x4A
;//question: 为什么0001的时候不行?
SHOW_COMMAND_INPUT := WM_USER + 0x0010
HIDE_COMMAND_INPUT := WM_USER + 0x00011
CANCEL_COMMAND_INPUT := WM_USER + 0x0100

global win
global startingStore := Map(
	"name", A_UserName
)
global student := Map(
	"name", A_UserName,
	"address", "上海"
)


global win
; win := WebViewGui("+Owner +ToolWindow +AlwaysOnTop -MinimizeBox  -MaximizeBox -Border -SysMenu  -Caption ")
win := WebViewGui("Resize -Caption")

; win.BrowseFolder "VueFramework"
win.BrowseFolder "D:\\program\\AutoHotkey\\WebCommandLine\\webcommandline\\dist"
win.Navigate "index.html"
; win.Navigate "/"
win.Show "w800 h600"


; 显示窗口的热键（Win+2）
#s:: {
	global win
	DetectHiddenWindows(true)
	if !WinExist("ahk_id " win.Hwnd)
		return
	win.Show("w800 h600")
}


#a:: {

	MsgBox win.IsVisible()
}

#b:: {

	win.Hide()
}

#c:: {
	win.Show()
}


WebButtonClickEvent(button) {
	MsgBox "You clicked the " button " button"
}

FormSubmit(formData) {
	MsgBox(
		"Email: " formData.email "`n"
		"Password: " formData.password "`n"
		"Address: " formData.address "`n"
		"Address2: " formData.address2 "`n"
		"City: " formData.city "`n"
		"State: " formData.state "`n"
		"Zip: " formData.zip "`n"
		"Check: " formData.check "`n"
	)
}


Button1() {
	win.ExecuteScriptAsync("logStudentInfo()")
	MsgBox "You clicked button 1"
}
Button2() {
	; student.Set(["address", "背景"])
	; student.Set("name", "张三")
	; message := JSON.stringify({ target: "updateChart", data: student })
	; win.PostWebMessageAsJson(message)
	MsgBox "You clicked button 2"
}
; MyString := "Hello!"
; MyWindow.ExecuteScript("MyFunc('" MyString "');")
; 	...
; 	// on the webpage you can write the the following function
; function MyFunc(Msg) {
; 	alert(Msg);
; }

SubmitForm(data) {
	MsgBox data.toSend
}
/**
 * MyCallback(wParam, lParam, msg, hwnd) { ...
 * 虽然给参数的名称并不重要, 但是下面的值会依次赋值给它们:
 * 
 * 消息的 WPARAM 值.
 * 消息的 LPARAM 值.
 * 消息号, 可用在用一个回调监听多个消息时.
 * 发送消息到的窗口或控件的 HWND(唯一 ID). HWND 可以直接在 WinTitle 参数中使用.
 * 
 */
; 4. 使用 OnMessage 注册回调函数。
;    当接收到 MY_CUSTOM_MESSAGE (0x5555) 消息时，会自动调用 HandleMyMessage 函数。
OnMessage(WM_CHAR, HandleMyMessage)
OnMessage(SHOW_COMMAND_INPUT, HandleMyMessage)
OnMessage(HIDE_COMMAND_INPUT, HandleMyMessage)
OnMessage(CANCEL_COMMAND_INPUT, HandleMyMessage)
/**
 * 接收端处理建议
 * 接收端可用统一方式解析：
 * 
 * 虽然参数是传递过来的，但有几个极其重要的限制：
 * A. 只能传递整数
 * PostMessage 和 OnMessage 的机制源自 Windows API。wParam 和 lParam 本质上是指针大小的整数（32位系统是32位整数，64位系统是64位整数）。
 * 你能传： 数字（如 123）、布尔值（0 或 1）、内存地址（指针）。
 * 你不能直接传： 字符串（如 "Hello"）、AHK 数组、对象。
 * 错误写法： PostMessage(0x1234, "你好", ...) —— 这样接收端收到的是莫名其妙的数字（字符串的内存地址或垃圾值），如果跨进程发送，这个地址在对方进程中是无效的，读取会导致崩溃。
 * B. 跨进程传递字符串的特殊方法
 * 如果你需要在两个不同的 AHK 脚本之间传递字符串，不能直接用 lParam。你需要使用 WM_COPYDATA (0x004A) 消息。这是一种特殊的 Windows 机制，系统会帮你把字符串数据从一个进程的内存复制到另一个进程。
 * 
 * 
 */
OnMessage(WM_COPYDATA, HandleAnyCopyData)

HandleAnyCopyData(wParam, lParam, msg, hwnd) {
	OutputDebug("wParam:" wParam " ,lParam:" lParam " msg:" msg ",hwnd:" hwnd)
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




showCommandLineWin() {
	DetectHiddenWindows(true)
	if !WinExist("ahk_id " win.Hwnd)
		return
	win.Show("w800 h600")
}
hideCommandLineWin() {
	win.Hide()
	command := {
		command: "clearAllCommandChar"
	}
	message := JSON.stringify(command)
}

receiveCommandChar(cmChar) {
	command := {
		data: cmChar,
		command: "receiveCommandChar"
	}
	message := JSON.stringify(command)
	win.PostWebMessageAsJson(message)
}




/**
 * 5. 定义回调函数 (消息处理器)
 * 函数签名: Callback(wParam, lParam, Msg, Hwnd)
 * 
 * wParam 和 lParam 是 Windows 消息机制中的两个通用参数，用于传递与特定消息相关的附加信息。它们的具体含义完全取决于 Msg 的值。它们本身没有固定意义，只是两个“数据容器”。
 * wParam: Word Parameter (字参数)
 * lParam: Long Parameter (长整型参数)
 * 
 * wParam (Word Parameter - 字参数)
 * 历史: 在 16 位系统中，一个 "Word"（字）是 16 位（2 字节）长。wParam 通常用来传递较小的数据，如一个句柄、一个整数 ID、或者一个字符码。
 * 简称: w-Param。
 * 
 * 
 * 
 * lParam (Long Parameter - 长整型参数)
 * 历史: 在 16 位和 32 位系统中，一个 "Long"（长整型）是 32 位（4 字节）长。lParam 通常用来传递更大的数据。一个非常常见的用法是将两个 16 位的值“打包”到一个 32 位的 lParam 中（例如鼠标的 X 和 Y 坐标），或者用它来传递一个指向更大数据结构（如一个字符串或一个结构体）的 内存地址（指针）。
 * 简称: l-Param
 * 
 * 在 键盘字符消息 WM_CHAR (0x102) 中 (1) wParam: 0x8 - 字符的 ASCII / Unicode 码。这里是退格键。 (2) lParam: 0 - 包含附加信息，如按键重复次数、扫描码等（在这里我们忽略了它
 * 在鼠标左键按下消息 WM_LBUTTONDOWN (0x201) (1)wParam: 1 (MK_LBUTTON) - 指示在点击时有哪些虚拟键（如 Ctrl, Shift）和鼠标按钮被按下。这里 1 表示左键本身被按下。(2) lParam: lParamValue - 包含了鼠标的坐标。低 16 位是 X 坐标，高 16 位是 Y 坐标
 * 
 * 在设置窗口文本消息 WM_SETTEXT (0x000C)  (1) wParam: 0 - 在这个消息中未使用 (2)lParam: &newTitle - 指向新标题字符串的内存地址（指针）。接收方会根据这个地址去内存中读取完整的字符串。
 */

HandleMyMessage(wParam, lParam, msgId, hwnd) {
	;PostMessage(msgNumber, wParam, 0)
	; wParam 和 lParam 是由发送方传递过来的数据。
	; msg 是消息的编号 (在这里就是 0x5555)。
	; hwnd 是接收消息的窗口句柄。

	OutputDebug("wParam: " wParam " lParam:" lParam "msgId:" msgId "hwnd:" hwnd)

	if (msgId == WM_CHAR) {

		; 从 wParam 获取字符码
		charCode := wParam
		;发送方会使用 :Ord(...)：获取这个字符的 Unicode 编码（十进制）
		; 将十六进制Unicode字符码转换为实际字符
		receivedChar := Chr(charCode)

		OutputDebug("{" receivedChar "}")

		if (charCode == BackSpaceHexCode) {
			; 如果是退格键
			OutputDebug("当前接收到哦的字符是{Backspace}")
		} else {
			; 如果是其他字符
		}
		; 对于某些消息，返回一个值可以阻止它被进一步处理
		; 这里我们返回 0，表示我们处理完了
		receiveCommandChar(receivedChar)
		return 0

	} else if (msgId == SHOW_COMMAND_INPUT) {
		; MsgBox("show command ")
		showCommandLineWin()
		return 0

	} else if (msgId == HIDE_COMMAND_INPUT) {
		MsgBox("Hidden command ")
		; hideCommandLineWin()
		return 0

	} else if (msgId == CANCEL_COMMAND_INPUT) {

		MsgBox("Cancel command")
		;hideCommandLineWin()
		return 0

	}

	; 根据 wParam 的值来执行不同的操作
	if (wParam = 1) {
		; 命令 1: 显示一个 MsgBox
		; lParam 在这里被用作要显示的消息内容。
		; 注意：在v2中，lParam 可能是整数或指针。如果发送的是字符串，
		; 需要用 StrGet() 从其内存地址读取。
		receivedText := StrGet(lParam)
		MsgBox "接收到命令 1！`n内容: " receivedText, "来自 Receiver", "Iconi"

		; 返回一个值给 SendMessage 的调用方
		return "MsgBox 命令已处理"

	} else if (wParam = 2) {
		; 命令 2: 显示一个 ToolTip
		; lParam 在这里被用作要显示的 ToolTip 持续时间（毫秒）。
		receivedText := StrGet(lParam)
		ToolTip receivedText, , , 1
		SetTimer () => ToolTip(), -3000 ; 3秒后清除 ToolTip

		; 返回一个值
		return "ToolTip 命令已处理"

	} else {
		; MsgBox "接收到未知命令！`nwParam: " wParam "`nlParam: " lParam, "来自 Receiver", "Icon!"
		; return "未知命令"
	}
	return 0
}