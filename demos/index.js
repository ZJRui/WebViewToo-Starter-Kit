
function  logStudentInf2(){

    console.log(window.student)
}


async function  logStudentInfo(){
    let studentName = await ahk.global.student.Get(ahk.global.student, "name")
    console.log("name",studentName)    
}
