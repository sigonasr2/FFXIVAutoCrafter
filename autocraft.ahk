Stdout(output:="", sciteCheck := true){	;output to console	-	sciteCheck reduces Stdout/Stdin performance,so where performance is necessary disable it accordingly
	Global ___console___, DEBUGMODE
	If (sciteCheck && ProcessExist("SciTE.exe") && GetScriptParentProcess() = "SciTE.exe"){	;if script parent is scite,output to scite console & return
		FileAppend, %output%`n, *
		Return
	}																												;CONOUT$ is a special file windows uses to expose attached console output
	if (DEBUGMODE) {
		( output ? ( !___console___? (DllCall("AttachConsole", "int", -1) || DllCall("AllocConsole")) & (___console___:= true) : "" ) & FileAppend(output . "`n","CONOUT$") : DllCall("FreeConsole") & (___console___:= false) & StdExit() )
	}
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

;Normal - 0xAAAAAA
;Good - 0xB569FF 160 284
;Excellent - 0xEEEEEE 233 282
;BGR
;Crafting Window - 0xFFFFFF 1283 655
;Action Ready - 0x636663 
;Action Not Ready - 3E3F3E
;100% Quality - 0x60DC97 336 269

WaitForCraftingWindow() {
	global toggle
	Stdout("Waiting for Crafting Window...")
	sleep, 500
	loop {
		MouseGetPos,MouseX,MouseY
		PixelGetColor,color,%MouseX%,%MouseY%
		Stdout(color . " " . MouseX . " " . MouseY)
		sleep, 50
	} until (CraftingWindowOpen() or !toggle)
	if (toggle) {
		send, {Numpad0}
		sleep, 50
		send, {Numpad0}
		sleep, 1000
		if (!CraftingWindowOpen()) {
			return true
		} else {
			return false
		}
	} else {
		return false
	}
}

ChooseConserveBestProgressStep(ByRef step,ByRef cp,cp_save,ByRef durability,stepcount=1) {
	if (cp-cp_save >= 32) {
		StandardTouch(step,cp,durability,stepcount)
	} else 
	if (cp-cp_save >= 18) {
		BasicTouch(step,cp,durability,stepcount)
	} else
	{
		HastyTouch(step,cp,durability,stepcount)
	}
}

ChooseBestProgressStep(ByRef step,ByRef cp,ByRef durability,stepcount=1) {
	;Stdout("Choosing progress step... " . step . "/" . cp . "/" . durability)
	if (cp >= 32) {
		;Stdout("Picking Standard Touch")
		StandardTouch(step,cp,durability,stepcount)
	} else
	if (cp >= 18) {
		BasicTouch(step,cp,durability,stepcount)
	} else
	{
		HastyTouch(step,cp,durability,stepcount)
	}
}

WaitForReady() {
	global toggle
	loop {
		Stdout("Waiting for Ready...")
		sleep, 250
	} until (ActionReady() or !toggle or CraftingWindowOpen())
	if (!toggle or CraftingWindowOpen()) {
		return false
	} else {
		return true
	}
}

DisplayInfo(step,cp,durability) {
	global WASTENOT
	DEBUGSTRING := "Step " . step . ": " . cp . "CP, " . durability . " durability"
	DEBUGSTRING := DEBUGSTRING . "/ WASTENOT: " . WASTENOT
	return DEBUGSTRING
}

CraftingRotationTemplate(ByRef STEP) {
	global toggle, CP, RECIPEDONE
	FINALSTEP = 13
	DURABILITY := 40
	
	loop {
		if (IsMaxQuality()) {
			STEP := FINALSTEP
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				INNERQUIET(STEP,CP,DURABILITY)
			Case 2:
				if (IsExcellent()) {
					BASICTOUCH(STEP,CP,DURABILITY,0)
					WaitForReady()
					WASTENOT(STEP,CP,DURABILITY,0)
				}
				TricksOfTheTrade(CP)
					WASTENOT(STEP,CP,DURABILITY)
			Case 3, 4, 5, 6, 7:
				if ((IsGood() or IsExcellent()) and CP > 160) {
					BASICTOUCH(STEP,CP,DURABILITY)
				} else {
					HASTYTOUCH(STEP,CP,DURABILITY)
				}
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}


QuickAccCraftRotation(ByRef STEP) {
	global toggle, CP, RECIPEDONE
	FINALSTEP = 7
	DURABILITY := 40
	
	loop {
		if (IsMaxQuality() or (DURABILITY = 5 and WASTENOT > 0) or (DURABILITY = 10 and WASTENOT = 0)) {
			BASICSYNTHESIS(STEP,CP,DURABILITY)
			STEP := 999
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				INNERQUIET(STEP,CP,DURABILITY)
			Case 2:
				WASTENOTII(STEP,CP,DURABILITY)
			Case 3,4,5:
				BASICTOUCH(STEP,CP,DURABILITY)
			Case 6:
				if (IsGood() or IsExcellent()) {
					BASICTOUCH(STEP,CP,DURABILITY,0)
				}
				INNOVATION(STEP,CP,DURABILITY)
			Case 7:
				BASICTOUCH(STEP,CP,DURABILITY,0)
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

QuickerCraftRotation(ByRef STEP) {
	global toggle, CP, RECIPEDONE
	FINALSTEP = 2
	DURABILITY := 40
	
	loop {
		if (IsMaxQuality()) {
			STEP := FINALSTEP
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				if (DURABILITY = 10) {
					STEP := 99
					send, {1}
					ProgressStep(STEP,CP,0)
					return
				} else {
					ChooseBestProgressStep(STEP,CP,DURABILITY)
					STEP := 1
				}
			Case 2:
				send, {1}
				ProgressStep(STEP,CP,0)
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

QuickCraftRotation(ByRef STEP) {
	global toggle, GREATSTRIDES, INNOVATION, CP, RECIPEDONE
	FINALSTEP = 3
	
	DURABILITY := 40
	
	SIDESTEPS = 0
	ACTIVATESIDESTEP := false
	
	loop {
		if (IsMaxQuality()) {
			STEP := FINALSTEP
			RECIPEDONE := true
		}
		
		Switch STEP
		{
			Case 1:
				send, {5}
				ProgressStep(STEP,CP,18)
			Case 2:
				if (DURABILITY = 10) {
					STEP := 99
					send, {1}
					ProgressStep(STEP,CP,0)
					return
				} else {
					STEP := 1
					if (GREATSTRIDES = 0) {
						TricksOfTheTrade(CP)
						GREATSTRIDES(STEP,CP,DURABILITY)
					} else
					if (!IsGood() and !IsExcellent() and INNOVATION = 0) {
						Innovation(STEP,CP,DURABILITY)
					} else 
					{
						ChooseBestProgressStep(STEP,CP,DURABILITY)
					}
				}
			Case 3:
				send, {1}
				ProgressStep(STEP,CP,0)
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

StrongCraft70(ByRef STEP) {
	global toggle, GREATSTRIDES, INNOVATION, CP, RECIPEDONE
	FINALSTEP = 3
	
	SIDESTEPS = 0
	ACTIVATESIDESTEP := false
	DURABILITY := 70
	
	loop {
		if (IsMaxQuality() or DURABILITY <= 20) {
			Veneration(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY)
			STEP := 99
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				InnerQuiet(STEP,CP,DURABILITY)
			Case 2:
				if (GREATSTRIDES = 0) {
					TricksOfTheTrade(CP)
					GreatStrides(STEP,CP,DURABILITY,0)
				}
				if (IsGood() or IsExcellent()) {
					ChooseConserveBestProgressStep(STEP,CP,18,DURABILITY,0)
				}
				STEP := 3
			Case 3:				
				if (INNOVATION = 0) {
					Innovation(STEP,CP,DURABILITY,0)
				}
				if (GREATSTRIDES > 0 or CP <= 32) {
					ChooseConserveBestProgressStep(STEP,CP,18,DURABILITY,0)
				}
				STEP := 2
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

StrongCraft60(ByRef STEP) {
	global toggle, GREATSTRIDES, INNOVATION, CP, RECIPEDONE
	FINALSTEP = 3
	
	SIDESTEPS = 0
	ACTIVATESIDESTEP := false
	DURABILITY := 80
	
	loop {
		if (IsMaxQuality() or DURABILITY <= 20) {
			Veneration(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY)
			STEP := 99
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				InnerQuiet(STEP,CP,DURABILITY)
			Case 2:
				if (GREATSTRIDES = 0) {
					TricksOfTheTrade(CP)
					GreatStrides(STEP,CP,DURABILITY,0)
				}
				if (IsGood() or IsExcellent()) {
					ChooseConserveBestProgressStep(STEP,CP,18,DURABILITY,0)
				}
				STEP := 3
			Case 3:				
				if (INNOVATION = 0) {
					Innovation(STEP,CP,DURABILITY,0)
				}
				if (GREATSTRIDES > 0 or CP <= 32) {
					ChooseConserveBestProgressStep(STEP,CP,18,DURABILITY,0)
				}
				STEP := 2
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

LongCraft70(ByRef STEP) {
	global toggle, CP, RECIPEDONE
	FINALSTEP = 13
	
	SIDESTEPS = 0
	ACTIVATESIDESTEP := false
	DURABILITY := 70
	
	loop {
		if (IsMaxQuality()) {
			Veneration(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY)
			STEP := 99
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				InnerQuiet(STEP,CP,DURABILITY)
			Case 2:
				TricksOfTheTrade(CP)
				WasteNot(STEP,CP,DURABILITY)
			Case 3,4,5,6:
				if (IsGood() or IsExcellent()) {
					BasicTouch(STEP,CP,DURABILITY)
				} else {
					HastyTouch(STEP,CP,DURABILITY)
				}
			Case 7:
				TricksOfTheTrade(CP)
				WasteNot(STEP,CP,DURABILITY)
			Case 8:
				if (IsGood() or IsExcellent()) {
					BasicTouch(STEP,CP,DURABILITY,0)
				}
				Innovation(STEP,CP,DURABILITY)
			Case 9,10,11,12:
				if (CP >= 36) {
					BasicTouch(STEP,CP,DURABILITY)
				} else {
					HastyTouch(STEP,CP,DURABILITY)
				}
			Case 13:
				if (DURABILITY <= 20) {
					if (CP >= 74) {
						WasteNot(STEP,CP,DURABILITY,0)
						loop {
							ChooseConserveBestProgressStep(STEP,CP,18,DURABILITY,0)
						} until (DURABILITY = 10 or IsMaxQuality())
					}
					Veneration(STEP,CP,DURABILITY,0)
					BasicSynthesis(STEP,CP,DURABILITY,0)
					BasicSynthesis(STEP,CP,DURABILITY)
				} else {
					STEP := 12
				}
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

LongCraft60(ByRef STEP) {
	global toggle, CP, RECIPEDONE
	FINALSTEP = 13
	
	SIDESTEPS = 0
	ACTIVATESIDESTEP := false
	DURABILITY := 80
	
	loop {
		if (IsMaxQuality()) {
			Veneration(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY,0)
			BasicSynthesis(STEP,CP,DURABILITY)
			STEP := 99
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				InnerQuiet(STEP,CP,DURABILITY)
			Case 2:
				TricksOfTheTrade(CP)
				WasteNot(STEP,CP,DURABILITY)
			Case 3,4,5,6:
				if (IsGood() or IsExcellent()) {
					BasicTouch(STEP,CP,DURABILITY)
				} else {
					HastyTouch(STEP,CP,DURABILITY)
				}
			Case 7:
				TricksOfTheTrade(CP)
				WasteNot(STEP,CP,DURABILITY)
			Case 8:
				if (IsGood() or IsExcellent()) {
					BasicTouch(STEP,CP,DURABILITY,0)
				}
				Innovation(STEP,CP,DURABILITY)
			Case 9,10,11,12:
				if (CP >= 36) {
					BasicTouch(STEP,CP,DURABILITY)
				} else {
					HastyTouch(STEP,CP,DURABILITY)
				}
			Case 13:
				if (DURABILITY <= 20) {
					if (CP >= 74) {
						WasteNot(STEP,CP,DURABILITY,0)
						loop {
							ChooseConserveBestProgressStep(STEP,CP,18,DURABILITY,0)
						} until (DURABILITY = 10 or IsMaxQuality())
					}
					Veneration(STEP,CP,DURABILITY,0)
					BasicSynthesis(STEP,CP,DURABILITY,0)
					BasicSynthesis(STEP,CP,DURABILITY)
				} else {
					STEP := 12
				}
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

CraftingRotation(ByRef STEP) {
	global toggle, CP, RECIPEDONE, WASTENOT
	FINALSTEP = 6
	
	SIDESTEPS = 0
	ACTIVATESIDESTEP := false
	DURABILITY := 40
	
	loop {
		if (IsMaxQuality()) {
			STEP := FINALSTEP
			RECIPEDONE := true
		}
		Switch STEP
		{
			Case 1:
				InnerQuiet(STEP,CP,DURABILITY)
			Case 2:
				if (IsExcellent()) {
					BasicTouch(STEP,CP,DURABILITY,0)
				}
				TricksOfTheTrade(CP)
				WasteNot(STEP,CP,DURABILITY)
			Case 3:
				if (DURABILITY > 10) {
					if (IsGood() or IsExcellent()) {
						BasicTouch(STEP,CP,DURABILITY)
					} else {
						HastyTouch(STEP,CP,DURABILITY)
					}
					STEP := 3
				} else {
					STEP := STEP + 1
				}
			Case 4:
				TricksOfTheTrade(CP)
				MastersMend(STEP,CP,DURABILITY,0)
				if (IsExcellent()) {
					BasicTouch(STEP,CP,DURABILITY,0)
				}
				TricksOfTheTrade(CP)
				WasteNot(STEP,CP,DURABILITY,0)
				if (IsExcellent()) {
					BasicTouch(STEP,CP,DURABILITY,0)
				}
				TricksOfTheTrade(CP)
				if (!Innovation(STEP,CP,DURABILITY)) {
					RECIPEDONE := true
					STEP := FINALSTEP+1
					Stdout("Something went wrong! Could not perform Innovation!")
				}
			Case 5:
				if (DURABILITY > 10) {
					if (IsExcellent() or IsGood()) {
						if (CP >= 18) {
							BasicTouch(STEP,CP,DURABILITY)
						} else {
							HastyTouch(STEP,CP,DURABILITY)
						}
					} else 
					{
						if (DURABILITY = 20 and CP >= 18) {
							ChooseBestProgressStep(STEP,CP,DURABILITY)
						} else {
							HastyTouch(STEP,CP,DURABILITY)
						}
					}
					STEP := 5
				} else {
					STEP := STEP + 1
				}
			Case 6:
				BasicSynthesis(STEP,CP,DURABILITY)
		}
		Stdout(DisplayInfo(STEP,CP,DURABILITY))
	} until (STEP >= FINALSTEP + 1 or !toggle)
}

SkillTemplate(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) { ;Optionally remove DURABILITY IF NOT REQUIRED.
	CPCOST := 18 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes inside ModDurability.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) { ;To prevent a touch from destroying an item, change >= to >
		send, {5} ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		return true
	} else {
		return false
	}
}

Veneration(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global VENERATION
	CPCOST := 18 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Shift","1") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		VENERATION := 4
		return true
	} else {
		return false
	}
}

GreatStrides(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global GREATSTRIDES
	CPCOST := 32 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","5") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		GREATSTRIDES := 4
		return true
	} else {
		return false
	}
}

HastyTouch(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global GREATSTRIDES
	CPCOST := 0 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(10) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY > DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","3") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		GREATSTRIDES := 0
		return true
	} else {
		return false
	}
}

Innovation(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global INNOVATION
	CPCOST := 18 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		send, {4} ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		INNOVATION := 4
		return true
	} else {
		return false
	}
}

MastersMend(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	CPCOST := 88 ;CP Cost goes here.
	DURABILITYCOST := -30 ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		send, {3} ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		;sleep, 2000
		return true
	} else {
		return false
	}
}

Observe(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	CPCOST := 7 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","X") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		return true
	} else {
		return false
	}
}

BrandOfTheElements(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	CPCOST := 6 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(10) ;Durability Cost goes here.
	if (CP >= CPCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","X") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		return true
	} else {
		return false
	}
}

NameOfTheElements(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global NAMEOFTHEELEMENTS
	CPCOST := 30 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","Z") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		NAMEOFTHEELEMENTS := 3
		return true
	} else {
		return false
	}
}

FinalAppraisal(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global FINALAPPRAISAL
	CPCOST := 1 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Alt","1") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		FINALAPPRAISAL := 5
		return true
	} else {
		return false
	}
}

RapidSynthesis(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global GREATSTRIDES
	CPCOST := 0 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(10) ;Durability Cost goes here.
	if (CP >= CPCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Shift","4") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		GREATSTRIDES := 0
		return true
	} else {
		return false
	}
}

StandardTouch(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global GREATSTRIDES
	CPCOST := 32 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(10) ;Durability Cost goes here.
	Stdout(CPCOST . "/" . DURABILITYCOST . "/" . CP . "/" . DURABILITY)
	if (CP >= CPCOST and DURABILITY > DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Shift","2") ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		GREATSTRIDES := 0
		return true
	} else {
		return false
	}
}

BasicTouch(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global GREATSTRIDES
	CPCOST := 18 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(10) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY > DURABILITYCOST and KeyPressAllowed()) {
		send, {2} ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		GREATSTRIDES := 0
		return true
	} else {
		return false
	}
}

BasicSynthesis(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	CPCOST := 0 ;CP Cost goes here.
	DURABILITYCOST := ModDurability(10) ;Durability Cost goes here.
	if (CP >= CPCOST and KeyPressAllowed()) {
		send, {1} ;Use PressKeyWithModifier("Ctrl","1") for modifiers.
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		return true
	} else {
		return false
	}
}

InnerQuiet(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	CPCOST := 18
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		send, {5}
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		return true
	} else {
		return false
	}
}

WasteNot(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global WASTENOT
	CPCOST := 56
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","1")
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		WASTENOT := 4
		Stdout("WASTENOT set to " . WASTENOT)
		return true
	} else {
		return false
	}
}

WasteNotII(ByRef STEP,ByRef CP,ByRef DURABILITY,stepcount=1) {
	global WASTENOT
	CPCOST := 98
	DURABILITYCOST := ModDurability(0) ;Durability Cost goes here.
	if (CP >= CPCOST and DURABILITY >= DURABILITYCOST and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","4")
		ProgressStep(STEP,CP,CPCOST,stepcount)
		DURABILITY := DURABILITY - DURABILITYCOST
		WASTENOT := 8
		Stdout("WASTENOT set to " . WASTENOT)
		return true
	} else {
		return false
	}
}

ModDurability(durability) {
	global WASTENOT
	if (WASTENOT > 0) {
		DURABILITYCOST := durability / 2
		Stdout("WASTENOT is on. " . DURABILITYCOST . " will be used.")
		return DURABILITYCOST
	} else {
		DURABILITYCOST := durability
		Stdout("WASTENOT is off. " . DURABILITYCOST . " will be used.")
		return DURABILITYCOST
	}
}

PressKeyWithModifier(modifier,key) {
	Send, {%modifier% down}
	sleep, 50
	Send, %key%
	sleep, 50
	Send, {%modifier% up}
}

TricksOfTheTrade(ByRef cp) {
	if (IsGood() and KeyPressAllowed()) {
		PressKeyWithModifier("Ctrl","2")
		cp := cp + 20
		tempstep := 0
		tempcp := 0
		ProgressStep(tempstep,tempcp,0)
		loop {
			sleep, 250
		} until ActionReady()
		return true
	} else {
		return false
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

KeyPressAllowed() {
	if (!CraftingWindowOpen()) {
		return true
	} else {
		return false
	}
}


CraftingWindowOpen() {
	PixelGetColor,ScreenCol,1282,668
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

SimpleTest() {
	Stdout("Output")
}


ProgressStep(ByRef step,ByRef cp,cpcost,stepamt=1) {
	global WASTENOT, INNOVATION, GREATSTRIDES, VENERATION, NAMEOFTHEELEMENTS, FINALAPPRAISAL, toggle, RECIPEDONE
	if (WASTENOT > 0) {
		WASTENOT := WASTENOT - 1
		Stdout("WASTENOT reduced to " . WASTENOT)
	}
	if (INNOVATION > 0) {
		INNOVATION := INNOVATION - 1
	}
	if (GREATSTRIDES > 0) {
		GREATSTRIDES := GREATSTRIDES - 1
	}
	if (VENERATION > 0) {
		VENERATION := VENERATION - 1
	}
	if (NAMEOFTHEELEMENTS > 0) {
		NAMEOFTHEELEMENTS := NAMEOFTHEELEMENTS - 1
	}
	if (FINALAPPRAISAL > 0) {
		FINALAPPRAISAL := FINALAPPRAISAL - 1
	}
	cp := cp - cpcost
	step := step + stepamt
	;sleep, 250
	loop {
		Stdout("Waiting for Ready...")
		sleep, 250
	} until (ActionReady() or !toggle or RECIPEDONE or CraftingWindowOpen())
}

STEP = -9999
toggle := false
WASTENOT := 0
GREATSTRIDES := 0
INNOVATION := 0
NAMEOFTHEELEMENTS := 0
VENERATION := 0
FINALAPPRAISAL := 0
CPBASE := 280
RECIPEDONE := false

ScriptList := {"(40dura)Long Crafting Rotation":"CraftingRotation","(40dura)Quick Crafting Rotation":"QuickCraftRotation","(40dura)Quick Guaranteed Crafting Rotation":"QuickAccCraftRotation","(40dura)Quickest Crafting Rotation":"QuickerCraftRotation","(60+dura)Long Crafting Rotation":"LongCraft60","(60+dura)Quick Crafting Rotation":"StrongCraft60","(70dura)Long Crafting Rotation":"LongCraft70","(70dura)Quick Crafting Rotation":"StrongCraft70"}
;Stdout("Starting " . ScriptList[words])
;functioncall := ScriptList[words]
;%functioncall%(STEP)

scriptSelectionBox := null
buttonstart := null
buttonstop := null
cpBox := null
debugBox := null

DEBUGMODE := false

scriptName := ""

scriptChoices := ""

for key,val in ScriptList
	scriptChoices := scriptChoices . key . "|"
	
scriptChoices := scriptChoices . "|" . scriptChoices[0]
	
Gui, Add, Text,, Script Choice:
Gui, Add, DropDownList,vscriptSelectionBox w300 ys, %scriptChoices%
Gui, Add, Button,vbuttonstart gStartCraftingScript w90 section, Run Script
Gui, Add, Button,vbuttonstop gStopCraftingScript w90 ys, Stop
Gui, Add, Text,section, CP:
Gui, Add, Edit,gmodifyCP ys w75
Gui, Add, UpDown,vcpBox ys Range1-1000, %CPBASE%
Gui, Add, Text,xp+100 ys, Debug
Gui, Add, Checkbox,ys vdebugBox gmodifyDebug
Gui, Show

GuiControl, Disable, buttonstop

modifyDebug() {
	global debugBox, DEBUGMODE
	debug := false
	GuiControlGet, debug,,debugBox
	DEBUGMODE := debug
	Stdout("Set DEBUGMODE to " . DEBUGMODE)
}

modifyCP() {
	global cpBox, CPBASE
	boxcp := 0
	GuiControlGet, boxcp,,cpBox
	CPBASE := boxcp
	Stdout("Set Crafting CP to " . CPBASE)
}

StartCraftingScript() {
	global ScriptList, toggle, CPBASE, CP, RECIPEDONE
	GuiControlGet, scriptName, ,scriptSelectionBox
	functioncall := ScriptList[scriptName]
	Stdout("Starting " . functioncall)
	toggle := true
	GuiControl, Disable, buttonstart
	GuiControl, Enable, buttonstop
	sleep,100
	CP := CPBASE
	WinActivate, FINAL FANTASY XIV
	loop {
		STEP := 1
		CP := CPBASE
		WASTENOT := 0
		GREATSTRIDES := 0
		INNOVATION := 0
		NAMEOFTHEELEMENTS := 0
		VENERATION := 0
		FINALAPPRAISAL := 0
		RECIPEDONE := false
		Stdout("Beginning Craft " . scriptName)
		if (WaitForCraftingWindow()) {
			WaitForReady()
			%functioncall%(STEP)
		} else {
			StopCraftingScript()
		}
	} until (!toggle)
	return
}

StopCraftingScript() {
	global toggle
	toggle := false
	GuiControl, Enable, buttonstart
	GuiControl, Disable, buttonstop
	WinActivate
}

ClosedOnce := false

GuiClose:
if (!ClosedOnce) {
	ClosedOnce := true
} else {
	ExitApp
}
return


;Stdout("Toggle1: " . toggle)
F11::
StopCraftingScript() 
return

F12::
StartCraftingScript() 
return
