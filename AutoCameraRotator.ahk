; ================================
; КАК ПОЛЬЗОВАТЬСЯ
; ================================

; Установить AutoHotKey: https://www.autohotkey.com/
; Поправить настройки прямо в этом скрипте
; Двойным щелчком запустить скрипт (или в меню правой кнопки мыши "Run This Script" в Проводнике Windows)

; F1 - запустить вращение (загорится кнопка CapsLock на клавиатуре)
; CapsLock - остановить вращение
; F12 - выйти к чертям

; Трюк с CapsLock нужен для улучшения фреймрейта.
; То есть, это не то что я такой мудак и не повесил скрипт и на одну и ту же клавишу F1, 
; да и сканировать можно хоть каждую миллисекунду, но это визуально бьет по производительности.
; Возможно, если переписать это на C++, станет лучше.

; В оригинале писалось чтобы покрутить камеру в Sekio: Shadows Die Twice на стриме TheDREWZAJ
; Используются куски сакральных знаний с форумов, трюк с точным таймером я бы сам не осилил.

; ================================
; НАСТРОЙКИ
; ================================

Speed := 1 ; На сколько пикселей сдвигать за одно микродвижение мыши
MoveRate := 1 ; Автоматическая мягкая компенсация лага (вносит микрозадержки)

; Ручная жесткая компенсация лага
ForcedSmoothThreashold := 10 ; Каждые N тактов (с учетом компенсатора лага)
ForcedSmoothAmount := 2 ; Внести задержку вот во столько миллисекунд

; Плавность всё равно сосёт, надо с этим что-то делать.

StopKeyReactionThreashold := 100 ; Через столько миллисекунд скрипт поймёт, что ты отпустил капс и надо прекращать вращение

; ================================
; КОД
; ================================
#SingleInstance Ignore
Process, Priority, , High
SetTitleMatchMode, 2
#InstallKeybdHook
#InstallMouseHook
SendMode Input
FRemaps = 1

#If FRemaps && WinActive("ahk_class CSclass")
F1::move()
F12::exit()
#IfWinActive

move() {
    global Speed
    global MoveRate
    SetCapsLockState, On
    new MouseController().Move(Speed,0,-1,MoveRate)
}

exit() {
    ExitApp
}

initui() {
    Gui, Add, ListBox, w300 h200 hwndhOutput
    Gui, Add, Text, xm w300 center, Hit F12 to toggle on / off
    Gui, Show,, Mouse Watcher
}

sout(txt) 
{
    global hOutput
    GuiControl, , % hOutput, % txt
    sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput    
    Return
}
    
class MouseController {
	static MOUSEEVENTF_MOVE := 0x1
	static MOUSEEVENTF_WHEEL := 0x800

	Move(x, y, times := 1, rate := 1){
		this._MouseEvent(times, rate, this.MOUSEEVENTF_MOVE, x, y)
	}
	
	Wheel(dir, times := 1, rate := 10){
		static WHEEL_DELTA := 120
		this._MouseEvent(times, rate, this.MOUSEEVENTF_WHEEL, , , dir * WHEEL_DELTA)
	}
	
	_MouseEvent(times, rate, dwFlags := 0, dx := 0, dy := 0, dwData := 0){
        global StopKeyReactionThreashold
        global ForcedSmoothThreashold
        global ForcedSmoothAmount
		res:=LLMouse.getTimerResolution() ;

        Guard := 0
        ForcedSmoothCounter := 0
        Loop {

            if (Guard > StopKeyReactionThreashold) {
                if (0 = GetKeyState("CapsLock", "T")) {
                    break
                }
                Guard := 0
            } else {
                Guard := Guard + 1
            }

            if (ForcedSmoothCounter > ForcedSmoothThreashold) {
                Sleep ForcedSmoothAmount
                ForcedSmoothCounter := 0
            } else {
                ForcedSmoothCounter := ForcedSmoothCounter + 1
            }

            if (times != -1 && times == A_Index) break

			dt:=0
			DllCall("mouse_event", uint, dwFlags, int, dx ,int, dy, uint, dwData, int, 0)
			if (A_Index != times && rate) {	
				LLMouse.accurateSleep(rate,res)
            }
		}
	}

	accurateSleep(t,res)
	{
		static F := LLMouse.getQPF()
		Critical
		dt:=0
		if (t > res){
			DllCall("QueryPerformanceCounter", "Int64P", sT1)
			DllCall("Sleep", "Int", t-res)
			DllCall("QueryPerformanceCounter", "Int64P", sT2)
			dt:=(sT2-sT1)*1000/F
		}
		t-=dt
		DllCall( "QueryPerformanceCounter", Int64P,pTick ), cTick := pTick

		While( pTick-cTick <t*F/1000 ) {
			DllCall( "QueryPerformanceCounter", Int64P,pTick )
			Sleep -1 ;
		}
		Return 
	}
	
	getTimerResolution()
	{
		DllCall("ntdll.dll\NtQueryTimerResolution", "UPtr*", MinimumResolution, "UPtr*", MaximumResolution, "UPtr*", CurrentResolution)
		return Ceil(CurrentResolution/10000) ;
	}
	
	getQPF()
	{
		DllCall( "QueryPerformanceFrequency", Int64P,F)
		return F
	}
	
}
