#Requires AutoHotkey v2

#Include <JSON/JSON>

; This example displays a UI with interactive elements. It shows basic
; integrations like pushing data to the page for display, buttons on the page to
; invoke AHK functions, and a simple form submission strategy.
#Include ../WebViewToo/Lib/WebViewToo.ahk
g := WebViewGui("Resize")
g.AddTextRoute "index.html", "
(
<!DOCTYPE html>
<html>
<head>
    <style>div { margin-bottom: 0.5em; }</style>
</head>
<body>
    <div>
        Interactive page contents. Hello <span id="username">user</span>!
    </div>
    <div>
        <form onsubmit="submitForm(event)">
            <input type="text" name="toSend" placeholder="text to send"></input>
            <button type="submit">Submit</button>
        </form>
    </div>
    <div>
        <button onclick="ahk.global.button1()">Button 1</button>
        <button onclick="ahk.global.button2()">Button 2</button>
    </div>
    <script type="module">
        // script type="module" so we can use await

        // Set up a form submission function to pass the values to AHK
        window.submitForm = async function(event) {
            event.preventDefault();
            await ahk.global.SubmitForm({
                toSend: event.target.querySelector('[name="toSend"]').value
            });
        }

        // Populate the username element A_UserName	运行当前脚本的用户的登录名.
        const name = await ahk.global.A_UserName;
        document.querySelector('#username').innerText = name;

         let studentName =await ahk.global.student.Get(ahk.global.student, "name");
         console.log("name",studentName)    
      async function  logStudentInfoTwo(){
            let studentName = await ahk.global.student.Get(ahk.global.student, "name")
            console.log("name",studentName)    
        }

        

    </script>
    <script>
          async function  logStudentInfo(){
            let studentName = await ahk.global.student.Get(ahk.global.student, "name")
            console.log("name",studentName)    
        }
        
         
    </script>

    <script>
window.chrome.webview.addEventListener('message', handleWebMessage);

function handleWebMessage(event) {
    try {
        // name incoming data
        const message = event.data;

        // Attempt to call the specified function if it exists
        if (typeof window[message.target] === 'function') {
            window[message.target](message.data);
        } else {
            //console.error("Function " ,message.target," does not exist.");
            console.error(``Function ${message.target} does not exist.``);
        }
    } catch (error) {
        console.error("Error handling incoming message:", error);
    }
}

function updateChart(data){
console.log("data",data)
}
</script>
</body>
</html>
)"
g.Navigate "index.html"
g.Show "w800 h600"

Button1() {
    g.ExecuteScriptAsync("logStudentInfo()")
    MsgBox "You clicked button 1"
}

Button2() {
    ; student.Set(["address", "背景"])
    student.Set("name", "张三")
    message := JSON.stringify({ target: "updateChart", data: student })
    g.PostWebMessageAsJson(message)
    MsgBox "You clicked button 2"
}

SubmitForm(data) {
    MsgBox data.toSend
}


global student := Map(
    "name", A_UserName,
    "address", "上海"
)