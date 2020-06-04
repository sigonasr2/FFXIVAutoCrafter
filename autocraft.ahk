Stdout(output:="", sciteCheck := true){	;output to console	-	sciteCheck reduces Stdout/Stdin performance,so where performance is necessary disable it accordingly
	Global ___console___
	If (sciteCheck && ProcessExist("SciTE.exe") && GetScriptParentProcess() = "SciTE.exe"){	;if script parent is scite,output to scite console & return
		FileAppend, %output%`n, *
		Return
	}																												;CONOUT$ is a special file windows uses to expose attached console output
	( output ? ( !___console___? (DllCall("AttachConsole", "int", -1) || DllCall("AllocConsole")) & (___console___:= true) : "" ) & FileAppend(output . "`n","CONOUT$") : DllCall("FreeConsole") & (___console___:= false) & StdExit() )
}

Stdin(output:="", sciteCheck := true){	;output to console & wait for input & return input
	Global ___console___
	If (sciteCheck && ProcessExist("SciTE.exe") && GetScriptParentProcess() = "SciTE.exe"){	;if script parent is scite,output to scite console & return
		FileAppend, %output%`n, *
		Return
	}
	( output ? ( !___console___? (DllCall("AttachConsole", "int", -1) || DllCall("AllocConsole")) & (___console___:= true) : "" ) & FileAppend(output . "`n","CONOUT$") & (Stdin := FileReadLine("CONIN$",1)) : DllCall("FreeConsole") & (___console___:= false) & StdExit() )
	Return Stdin
}

StdExit(){
	If GetScriptParentProcess() = "cmd.exe"		;couldn't get this: 'DllCall("GenerateConsoleCtrlEvent", CTRL_C_EVENT, 0)' to work so...
		ControlSend, , {Enter}, % "ahk_pid " . GetParentProcess(GetCurrentProcess())
}

FileAppend(str, file){
	FileAppend, %str%, %file%
}

FileReadLine(file,lineNum){
	FileReadLine, retVal, %file%, %lineNum%
	return retVal
}

ProcessExist(procName){
	Process, Exist, % procName
	Return ErrorLevel
}

GetScriptParentProcess(){
	return GetProcessName(GetParentProcess(GetCurrentProcess()))
}

GetParentProcess(PID)
{
	static function := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "kernel32.dll", "ptr"), "astr", "Process32Next" (A_IsUnicode ? "W" : ""), "ptr")
	if !(h := DllCall("CreateToolhelp32Snapshot", "uint", 2, "uint", 0))
		return
	VarSetCapacity(pEntry, sz := (A_PtrSize = 8 ? 48 : 36)+(A_IsUnicode ? 520 : 260))
	Numput(sz, pEntry, 0, "uint")
	DllCall("Process32First" (A_IsUnicode ? "W" : ""), "ptr", h, "ptr", &pEntry)
	loop
	{
		if (pid = NumGet(pEntry, 8, "uint") || !DllCall(function, "ptr", h, "ptr", &pEntry))
			break
	}
	DllCall("CloseHandle", "ptr", h)
	return Numget(pEntry, 16+2*A_PtrSize, "uint")
}

GetProcessName(PID)
{
	static function := DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "kernel32.dll", "ptr"), "astr", "Process32Next" (A_IsUnicode ? "W" : ""), "ptr")
	if !(h := DllCall("CreateToolhelp32Snapshot", "uint", 2, "uint", 0))
		return
	VarSetCapacity(pEntry, sz := (A_PtrSize = 8 ? 48 : 36)+260*(A_IsUnicode ? 2 : 1))
	Numput(sz, pEntry, 0, "uint")
	DllCall("Process32First" (A_IsUnicode ? "W" : ""), "ptr", h, "ptr", &pEntry)
	loop
	{
		if (pid = NumGet(pEntry, 8, "uint") || !DllCall(function, "ptr", h, "ptr", &pEntry))
			break
	}
	DllCall("CloseHandle", "ptr", h)
	return StrGet(&pEntry+28+2*A_PtrSize, A_IsUnicode ? "utf-16" : "utf-8")
}

GetCurrentProcess()
{
	return DllCall("GetCurrentProcessId")
}


#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#MaxThreadsPerHotkey, 2 ;with this each hotkey can have more than 1 "thread" allowing us to execute "space::" again
                        ;even though it's still stuck in the loop.
;space::
;toggle:=!toggle
;loop {
;	send, {Numpad0} ;send the Enter key, which needs to be in brackets, then text "/oos" followed by another enter.
;	sleep, 100
;	send, {Numpad0}
;	sleep, 100
;	send, {Numpad0}
;	sleep, 2000
;	send, {Z}
;	sleep, 27500              ;sleep for 5000 milliseconds/5 seconds
;} until !toggle
;return

WinActivate, FINAL FANTASY XIV

;Normal - 0xAAAAAA
;Good - 0xB569FF 160 284
;Excellent - 0xEEEEEE 233 282
;BGR
;Crafting Window - 0xFFFFFF 1283 655
;Action Ready - 0x636663 
;Action Not Ready - 3E3F3E
;100% Quality - 0x60DC97 336 269

WaitForCraftingWindow() {
	Stdout("Waiting for Crafting Window...")
	sleep, 500
	loop {
		MouseGetPos,MouseX,MouseY
		PixelGetColor,color,%MouseX%,%MouseY%
		Stdout(color . " " . MouseX . " " . MouseY)
		sleep, 50
	} until CraftingWindowOpen()
	send, {Numpad0}
	sleep, 50
	send, {Numpad0}
	sleep, 50
	send, {Numpad0}
	sleep, 150
	if (!CraftingWindowOpen()) {
		return true
	} else {
		return false
	}
}

ProgressStep(ByRef step,ByRef cp,cpcost,stepamt=1) {
	cp -= cpcost
	step += stepamt
}
WaitForReady() {
	global toggle
	loop {
		Stdout("Waiting for Ready...")
		sleep, 250
	} until (ActionReady())
	if (!toggle) {
		return false
	} else {
		return true
	}
}

CraftingRotation(ByRef STEP) {
	global toggle
	CP = 252
	FINALSTEP = 13
	
	if (!WaitForReady()) {
		return
	}
	
	loop {
		if (IsMaxQuality()) {
			STEP = FINALSTEP
		}
		Switch STEP
		{
			Case 1:
				send, {5}
				ProgressStep(STEP,CP,18)
			Case 2:
				if (IsExcellent()) {
					send, {2}
					ProgressStep(STEP,CP,18,2)
					WaitForReady()
					PressKeyWithModifier("Ctrl","1")
					ProgressStep(STEP,CP,56,0)
				}
				TricksOfTheTrade(CP)
				PressKeyWithModifier("Ctrl","1")
				ProgressStep(STEP,CP,56)
			Case 3, 4, 5, 6, 7:
				if ((IsGood() or IsExcellent()) and CP > 160) {
					send, {2}
					ProgressStep(STEP,CP,18)
				} else {
					PressKeyWithModifier("Ctrl","3")
					ProgressStep(STEP,CP,0)
				}
			Case 8:
				TricksOfTheTrade(CP)
				send, {3}
				ProgressStep(STEP,CP,88)
			Case 9:
				TricksOfTheTrade(CP)
				send, {4}
				ProgressStep(STEP,CP,18)
			Case 10, 11, 12:
				if (CP > 54) {
					PressKeyWithModifier("Shift","2")
					ProgressStep(STEP,CP,32)
				} else {
					send, {2}
					ProgressStep(STEP,CP,18)
				}
			Case 13:
				send, {1}
				ProgressStep(STEP,CP,0)
		}
		
		loop {
			Stdout("Waiting for Ready...")
			sleep, 250
		} until (ActionReady() or STEP >= FINALSTEP + 1)
		Stdout("STEP " . STEP . ": " . CP)
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

PressKeyWithModifier(modifier,key) {
	Send, {%modifier% down}
	sleep, 50
	Send, %key%
	sleep, 50
	Send, {%modifier% up}
}

TricksOfTheTrade(ByRef cp) {
	if IsGood() {
		PressKeyWithModifier("Ctrl","2")
		cp += 20
		loop {
			sleep, 250
		} until ActionReady()
	}
}

ActionReady() {
	PixelGetColor,ScreenCol,1912,700
	if (SubStr(ScreenCol,3,6) = "636663") {
		return true
	} else {
		return false
	}
}


CraftingWindowOpen() {
	PixelGetColor,ScreenCol,1283,655
	if (SubStr(ScreenCol,3,6) = "FFFFFF") {
		return true
	} else {
		return false
	}
}

IsMaxQuality() {
	PixelGetColor,ScreenCol,336,269
	if (SubStr(ScreenCol,3,6) = "60DC97") {
		return true
	} else {
		return false
	}
}

IsGood() {
	PixelGetColor,ScreenCol,160,284
	if (SubStr(ScreenCol,7,2) = "FF") {
		return true
	} else {
		return false
	}
}

IsExcellent() {
	PixelGetColor,ScreenCol,233,282
	if (SubStr(ScreenCol,3,6) = "EEEEEE") {
		return true
	} else {
		return false
	}
}


STEP = -9999
toggle := false

;Stdout("Toggle1: " . toggle)
F11::
{
	toggle := !toggle
	Stdout("Toggle1: " . toggle)
}
return

F12::
loop {
	if !toggle {
		Stdout("Toggle was false. Toggle is now " . toggle)
		toggle = true
		break
	}
	Stdout("Crafting is on. Starting craft...")
	STEP = 1
	if (WaitForCraftingWindow()) {
		CraftingRotation(STEP)
	} else {
		toggle = false
		Stdout("Toggle4: " . toggle)
	}
	sleep, 250
} 
return
