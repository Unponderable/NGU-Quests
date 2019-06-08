Global Px ;Top Left Corner X coordinate
Global Py ;Top Left Corner Y coordinate
Global XPositionAdventure
Global YPositionAdventure
Global XPositionPreviousZone
Global YPositionPreviousZone
Global XPositionNextZone
Global YPositionNextZone
Global Y_Inventory
Global Y_Questing
Global WinW
Global WinH
Global XQuestAccept
Global XQuestSkip
Global YQuestButton
Global XConfirmSkipQuest
Global YConfirmSkipQuest

Global CurrentQuest
Global CurrentQuestAdvZones

Esc::ExitApp ;**Press Escape to end the script at anytime**

^j:: ;**Press CTRL+J to begin script loop**
{
	IfWinNotActive, Play NGU IDLE ;Kongregate
	{
		IfWinNotActive, ahk_exe NGUIdle.exe ;Kartridge
		{
			MsgBox, Failed to initiate - NGU Idle window not active.`nRun the script when the game window is active.
			Exit
		}
	}
	SetMouseDelay, 10
	SetKeyDelay, 10
	LoopCount := 0

	WinGetPos,,,WinW,WinH
	
	IfWinActive, Play NGU IDLE
	{
		SearchFileName = TopLeft.png
		ImageSearch, Px, Py, 0, 0, %WinW%, %WinH%, *10 %SearchFileName%
		if ErrorLevel{
			MsgBox, Failed to initiate - couldn't detect top left corner of NGU Idle using ImageSearch.`nMake sure the game is fully visible on your screen.`nExiting...
				Exit
		}
	}
	Else
	{
		IfWinActive, ahk_exe NGUIdle.exe
		{
			CoordMode, Mouse, Client
			CoordMode, Pixel, Client
			Px := 0
			Py := 0
		}
	}
	
	
	;Set the position of boxes relative to the top left corner. Determined in advance.
	XPositionAdventure := Px + 237 ;The Adventure button under Features
	YPositionAdventure := Py + 140
	XPositionPreviousZone := Px + 331 ;The left arrow in the Adventure menu
	YPositionPreviousZone := Py + 221
	XPositionNextZone := Px + 929 ;The right arrow in the Adventure menu
	YPositionNextZone := Py + 221
	Y_Inventory := Py + 537 - 375
	Y_Questing := Py + 841 - 375
	
	XQuestAccept := Px + 1040 - 330
	XQuestSkip := Px + 1200 - 330
	YQuestButton := Py + 537 - 375
	XConfirmSkipQuest := Px + 768 - 330
	YConfirmSkipQuest := Py + 690 - 375
	
	XInvPage1 := 360
	YInvPage := 572
	
	Loop{
		QuestDetect() ;Determine what quest is active and pick up a new quest if needed
		
		Adventure()
		Sleep, 100
		Click,right,%XPositionPreviousZone%, %YPositionPreviousZone% ;Safe Zone
		Sleep, 100
		Loop, %CurrentQuestAdvZones% { ;Go to quest's adventure zone
				Send,{Right}
				Sleep,100
		}
		
		
		Loop{
			Inventory()
				
			Loop, 5
			{
				XSpot := XInvPage1 + 67.5 * (A_Index - 1) ;Need to search all possible pages of inventory (current max: 5)
				Click,%XSpot%,%YInvPage%
				Sleep, 100
								
				
											
				ItemLocation := "questing_" . CurrentQuest . "_item.png"
				ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 %ItemLocation%
				
				if Xif ;If there's quest item in the inventory...
				{
					Click, right, %Xif%, %Yif% ;deposit all quest items
					Sleep, 500
					break
				}
			}
						
			
			Questing()
			MouseMove,Px,Py
			Sleep, 500
			ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_done.png
			if Xif ;If there's a quest ready to be completed...
			{ 
				Questing()
				Click, %XQuestAccept%, %YQuestButton% ;Complete it
				Sleep, 100
				break
			}
			
			FastIdle()
			
			Sleep, 1000
		}
	}
	
}

Adventure()
{
	Click %XPositionAdventure%, %YPositionAdventure%
	Sleep, 100
}

Inventory()
{
	Click %XPositionAdventure%, %Y_Inventory%
	Sleep, 100
}

Questing()
{
	Click %XPositionAdventure%, %Y_Questing%
	Sleep, 100
}

MajorQuestCheck() ;if major quest checkmark is checked, uncheck it. No longer used.
{
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_majqcheck.png
	if Xif
	{
		Click, %Xif%, %Yif%
	}
	Sleep, 100
}

FastIdle()
{
	Adventure()
	MouseMove,Px,Py
	Sleep, 500
	;Check if IDLE mode is already off
	XPositionYellowBorderAroundIdleMode := Px + 316 ;The tiny yellow border that surrounds Idle Mode when it's on
	YPositionYellowBorderAroundIdleMode := Py + 88
	PixelGetColor, idleborderpx, %XPositionYellowBorderAroundIdleMode%, %YPositionYellowBorderAroundIdleMode%, Alt ;Check border of idle mode for yellow color
	if colorcheck(idleborderpx,0x04EBFF)=1
	{
		Send,q ;Turn off Idle Mode
	}

	Sleep, 50
	Loop,100	{
		Loop{ ;Wait for spawn
			Sleep,5
		} Until FightingMonsterCheck() = 0
		Send,w
		T:=100-A_Index
		ToolTip,Checking inventory in %T% more kills
		Sleep, 1000
	}
	Send,q
	Tooltip
	Sleep,50
}

FightingMonsterCheck() ; Checks for white in the red enemy health bar
{
	X1 := Px + 1061 - 329
	Y1 := Py + 780 - 374	

	PixelSearch,,, X1, Y1, X1+4, Y1+4, 0xFFFFFF, 1, Fast
	if ErrorLevel
	{
		;MsgBox, That color was not found in the specified region, X%X1% Y%Y1%.
		return, 0
	}
	else
	{
		;MsgBox, A color within 3 shades of variation was found at X%X1% Y%Y1%.
		return, 1
	}
}
colorcheck(colorvalue,referencecolor) ;Converts hex to BGR and then compares values; returns 1 if within tolerance, returns 0 if not
{
    Red := colorvalue & 0xFF
    Green := colorvalue >> 8 & 0xFF
    Blue := colorvalue >> 16 & 0xFF
	
	RedRef := referencecolor & 0xFF
    GreenRef := referencecolor >> 8 & 0xFF
    BlueRef := referencecolor >> 16 & 0xFF
	
	if (Abs(Red-RedRef)<50) && (Abs(Green-GreenRef)<50) && (Abs(Blue-BlueRef)<50)
	{
		return, 1
	}
	else
	{
		return, 0
	}
}

QuestDetect()
{
	Questing()
	Sleep, 100
	MouseMove,Px,Py
	Sleep, 200
	
	Loop{
	
	;imagesearch for quest text
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_sewers_text.png
	if Xif
	{
		CurrentQuest := "sewers"
		CurrentQuestAdvZones := 2
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_forest_text.png
	if Xif
	{
		CurrentQuest := "forest"
		CurrentQuestAdvZones := 3
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_hsb_text.png
	if Xif
	{
		CurrentQuest := "hsb"
		CurrentQuestAdvZones := 6
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_2d_text.png
	if Xif
	{
		CurrentQuest := "2d"
		CurrentQuestAdvZones := 10
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_avsp_text.png
	if Xif
	{
		CurrentQuest := "avsp"
		CurrentQuestAdvZones := 13
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_mega_text.png
	if Xif
	{
		CurrentQuest := "mega"
		CurrentQuestAdvZones := 14
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_beardverse_text.png
	if Xif
	{
		CurrentQuest := "beardverse"
		CurrentQuestAdvZones := 16
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_cw_text.png
	if Xif
	{
		CurrentQuest := "cw"
		CurrentQuestAdvZones := 21
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_evilverse_text.png
	if Xif
	{
		CurrentQuest := "evilverse"
		CurrentQuestAdvZones := 22
		return
	}
	
	ImageSearch, Xif, Yif, 0, 0, %WinW%, %WinH%, *10 questing_ppp_text.png
	if Xif
	{
		CurrentQuest := "ppp"
		CurrentQuestAdvZones := 23
		return
	}
	Sleep, 100
	
	Click, %XQuestAccept%, %YQuestButton%
	Sleep, 100
	}
}