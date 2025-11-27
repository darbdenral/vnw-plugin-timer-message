; ============================================================
;  VisualNEO Win Plugin: PopupMessage.nbp
;  Action: PopupMessage_Show
;  Parameters:
;    0 - Title (string)
;    1 - Caption (string)
;    2 - Message (string)
;    3 - ButtonText (string)
;    4 - DurationSeconds (numeric)
;    5 - CallbackSubroutine (string, optional)
; ============================================================

EnableExplicit

; ------------------------------------------------------------
; Global function pointers supplied by VisualNEO Win
; ------------------------------------------------------------

Global g_nbAddAction.i
Global g_nbGetVar.i
Global g_nbSetVar.i
Global g_nbWinHandle.i     ; NeoBook main window handle
Global g_nbInterface.i     ; NeoBook interface for executing commands
Global g_nbPlayAction.i    ; NeoBook action script player

; Global pointers for plugin metadata strings (freed in DetachProcess)
Global *g_PluginTitle
Global *g_PluginAuthor
Global *g_PluginHint
Global *g_ActionName
Global *g_ActionHint

; ------------------------------------------------------------
; Utility: allocate and fill an NB string
; ------------------------------------------------------------

Procedure.i MakeNBString(text.s)
  Protected bytes.i = StringByteLength(text, #PB_Ascii) + 1
  Protected *p = GlobalAlloc_($0040, bytes)
  If *p
    PokeS(*p, text, -1, #PB_Ascii)
  EndIf
  ProcedureReturn *p
EndProcedure

; ------------------------------------------------------------
; Utility: write pointer to VisualNEO Win output pointer
; ------------------------------------------------------------

Procedure SetOutPtr_NoFree(*pDest.Long, *src)
  If *pDest
    PokeL(*pDest, *src)
  EndIf
EndProcedure

; ------------------------------------------------------------
; Forward declarations
; ------------------------------------------------------------
Declare SetNBVar(varName.s, value.s)
Declare CallNBSubroutine(subroutineName.s)

; ============================================================
; VisualNEO REQUIRED INTERFACE FUNCTIONS
; ============================================================

; ------------------------------------------------------------
; _nbInitPlugIn
; ------------------------------------------------------------
ProcedureDLL _nbInitPlugIn(hWnd.i, *pTitle.Long, *pAuthor.Long, *pHint.Long)
  g_nbWinHandle = hWnd  ; Store the NeoBook window handle

  *g_PluginTitle  = MakeNBString("Timer Message Plugin")
  *g_PluginAuthor = MakeNBString("Brad Larned")
  *g_PluginHint   = MakeNBString("Shows a customizable popup message with a timed autoclose.")

  SetOutPtr_NoFree(*pTitle, *g_PluginTitle)
  SetOutPtr_NoFree(*pAuthor, *g_PluginAuthor)
  SetOutPtr_NoFree(*pHint, *g_PluginHint)
EndProcedure

; ------------------------------------------------------------
; _nbRegisterPlugIn
; ------------------------------------------------------------
; Structure for parameter types
Structure TActionParams
  p.b[10]
EndStructure

ProcedureDLL _nbRegisterPlugIn(AddAction.i, AddFile.i, GetVar.i, SetVar.i)
  g_nbAddAction = AddAction
  g_nbGetVar = GetVar
  g_nbSetVar = SetVar

  If g_nbAddAction
    ; --- Register our single action ---
    *g_ActionName = MakeNBString("PopupMessage_Show")
    *g_ActionHint = MakeNBString("Show popup with title, caption, message, button, duration & optional callback.")

    ; Define parameter types
    Protected params.TActionParams
    params\p[0] = 1  ; title - ACTIONPARAM_ALPHA
    params\p[1] = 1  ; caption - ACTIONPARAM_ALPHA
    params\p[2] = 1  ; message - ACTIONPARAM_ALPHA
    params\p[3] = 1  ; button text - ACTIONPARAM_ALPHA
    params\p[4] = 3  ; duration - ACTIONPARAM_NUMERIC
    params\p[5] = 1  ; callback subroutine - ACTIONPARAM_ALPHA (optional)

    ; Call: nbAddAction(ID, Name, Hint, @Params, HighIndex, ParamCount)
    ; HighIndex = (Total Parameters - 1) = 5
    ; ParamCount = Total number of parameters = 6
    CallFunctionFast(g_nbAddAction, 1, *g_ActionName, *g_ActionHint, @params, 5, 6)
  EndIf
EndProcedure

; ------------------------------------------------------------
; _nbEditAction - Configuration dialog for the action
; ------------------------------------------------------------
; Gadget IDs for the configuration window
Enumeration
  #Window_Config
  #Text_Title
  #String_Title
  #Text_Caption
  #String_Caption
  #Text_Message
  #String_Message
  #Text_Button
  #String_Button
  #Text_Duration
  #String_Duration
  #Text_Callback
  #String_Callback
  #Button_OK
  #Button_Cancel
EndEnumeration

ProcedureDLL.i _nbEditAction(ID.i, *Params.Long)
  Protected Result.i = #False

  If ID = 1  ; PopupMessage_Show
    ; Read current parameter values
    Protected valTitle.s    = PeekS(PeekL(*Params + 0*4), -1, #PB_Ascii)
    Protected valCaption.s  = PeekS(PeekL(*Params + 1*4), -1, #PB_Ascii)
    Protected valMessage.s  = PeekS(PeekL(*Params + 2*4), -1, #PB_Ascii)
    Protected valButton.s   = PeekS(PeekL(*Params + 3*4), -1, #PB_Ascii)
    Protected valDuration.s = PeekS(PeekL(*Params + 4*4), -1, #PB_Ascii)
    Protected valCallback.s = PeekS(PeekL(*Params + 5*4), -1, #PB_Ascii)

    ; Open configuration window
    If OpenWindow(#Window_Config, 0, 0, 450, 320, "Configure Popup Message", #PB_Window_SystemMenu | #PB_Window_WindowCentered, GetActiveWindow_())

      ; Create input fields
      TextGadget(#Text_Title, 10, 15, 100, 20, "Title:")
      StringGadget(#String_Title, 120, 10, 320, 25, valTitle)

      TextGadget(#Text_Caption, 10, 55, 100, 20, "Caption:")
      StringGadget(#String_Caption, 120, 50, 320, 25, valCaption)

      TextGadget(#Text_Message, 10, 95, 100, 20, "Message:")
      StringGadget(#String_Message, 120, 90, 320, 25, valMessage)

      TextGadget(#Text_Button, 10, 135, 100, 20, "Button Text:")
      StringGadget(#String_Button, 120, 130, 320, 25, valButton)

      TextGadget(#Text_Duration, 10, 175, 100, 20, "Duration (sec):")
      StringGadget(#String_Duration, 120, 170, 100, 25, valDuration)

      TextGadget(#Text_Callback, 10, 215, 100, 20, "Callback (opt):")
      StringGadget(#String_Callback, 120, 210, 320, 25, valCallback)

      ButtonGadget(#Button_OK, 120, 270, 100, 30, "OK")
      ButtonGadget(#Button_Cancel, 240, 270, 100, 30, "Cancel")

      ; Event loop
      Protected Quit.b = #False
      Repeat
        Select WaitWindowEvent()
          Case #PB_Event_Gadget
            Select EventGadget()
              Case #Button_OK
                ; Save new values back to parameters
                Protected oldStr.i

                ; Free old strings and set new ones
                oldStr = PeekL(*Params + 0*4)
                If oldStr : GlobalFree_(oldStr) : EndIf
                PokeL(*Params + 0*4, MakeNBString(GetGadgetText(#String_Title)))

                oldStr = PeekL(*Params + 1*4)
                If oldStr : GlobalFree_(oldStr) : EndIf
                PokeL(*Params + 1*4, MakeNBString(GetGadgetText(#String_Caption)))

                oldStr = PeekL(*Params + 2*4)
                If oldStr : GlobalFree_(oldStr) : EndIf
                PokeL(*Params + 2*4, MakeNBString(GetGadgetText(#String_Message)))

                oldStr = PeekL(*Params + 3*4)
                If oldStr : GlobalFree_(oldStr) : EndIf
                PokeL(*Params + 3*4, MakeNBString(GetGadgetText(#String_Button)))

                oldStr = PeekL(*Params + 4*4)
                If oldStr : GlobalFree_(oldStr) : EndIf
                PokeL(*Params + 4*4, MakeNBString(GetGadgetText(#String_Duration)))

                oldStr = PeekL(*Params + 5*4)
                If oldStr : GlobalFree_(oldStr) : EndIf
                PokeL(*Params + 5*4, MakeNBString(GetGadgetText(#String_Callback)))

                Result = #True
                Quit = #True

              Case #Button_Cancel
                Quit = #True
            EndSelect

          Case #PB_Event_CloseWindow
            Quit = #True
        EndSelect
      Until Quit

      CloseWindow(#Window_Config)
    EndIf
  EndIf

  ProcedureReturn Result
EndProcedure

; ------------------------------------------------------------
; _nbExecAction
; ------------------------------------------------------------
; Helper: Set a NeoBook variable
Procedure SetNBVar(varName.s, value.s)
  If g_nbSetVar
    Protected *varNamePtr = MakeNBString(varName)
    Protected *valuePtr = MakeNBString(value)
    If *varNamePtr And *valuePtr
      CallFunctionFast(g_nbSetVar, *varNamePtr, *valuePtr)
      GlobalFree_(*varNamePtr)
      GlobalFree_(*valuePtr)
    EndIf
  EndIf
EndProcedure

ProcedureDLL.i _nbExecAction(ID.i, *Params.Long)
  Protected title.s
  Protected caption.s
  Protected message.s
  Protected button.s
  Protected duration.i
  Protected callback.s

  Select ID

    Case 1
      title    = PeekS(PeekL(*Params + 0*4), -1, #PB_Ascii)
      caption  = PeekS(PeekL(*Params + 1*4), -1, #PB_Ascii)
      message  = PeekS(PeekL(*Params + 2*4), -1, #PB_Ascii)
      button   = PeekS(PeekL(*Params + 3*4), -1, #PB_Ascii)
      duration = Val(PeekS(PeekL(*Params + 4*4), -1, #PB_Ascii))
      callback = PeekS(PeekL(*Params + 5*4), -1, #PB_Ascii)

      ; Custom popup with auto-close
      ; Get parent window position and size
      Protected rect.RECT
      Protected popupWidth.i = 300
      Protected popupHeight.i = 150
      Protected x.i, y.i

      If g_nbWinHandle And GetWindowRect_(g_nbWinHandle, @rect)
        ; Calculate position: centered in the middle of the form
        Protected formWidth.i = rect\right - rect\left
        Protected formHeight.i = rect\bottom - rect\top
        x = rect\left + ((formWidth - popupWidth) / 2)
        y = rect\top + ((formHeight - popupHeight) / 2)
      Else
        ; Fallback to center of screen
        x = (GetSystemMetrics_(#SM_CXSCREEN) - popupWidth) / 2
        y = (GetSystemMetrics_(#SM_CYSCREEN) - popupHeight) / 2
      EndIf

      Protected hwnd.i = OpenWindow(#PB_Any, x, y, popupWidth, popupHeight, caption, #PB_Window_SystemMenu | #PB_Window_Tool)

      If hwnd
        ; Center the button horizontally
        Protected buttonWidth.i = 100
        Protected buttonX.i = (popupWidth - buttonWidth) / 2
        Protected buttonY.i = 110
        ButtonGadget(100, buttonX, buttonY, buttonWidth, 30, button)

        ; Calculate vertical center for text between top margin and button
        Protected textHeight.i = 60
        Protected topMargin.i = 10
        Protected availableSpace.i = buttonY - topMargin
        Protected textY.i = topMargin + ((availableSpace - textHeight) / 2)

        ; Create text gadget for the message - centered horizontally and vertically, multiline
        Protected textGadgetID.i = TextGadget(#PB_Any, 10, textY, 280, textHeight, message, #PB_Text_Center)

        ; Initialize countdown tracking
        Protected secondsLeft.i = duration
        Protected startTime.i = ElapsedMilliseconds()
        Protected baseCaption.s = caption
        Protected baseMessage.s = message

        ; Set initial countdown variable
        SetNBVar("PopupSecondsLeft", Str(secondsLeft))

        ; Update initial display with countdown
        If duration > 0
          ; Replace both {COUNTDOWN} placeholder and [PopupSecondsLeft] variable
          Protected displayCaption.s = ReplaceString(baseCaption, "{COUNTDOWN}", Str(secondsLeft))
          displayCaption = ReplaceString(displayCaption, "[PopupSecondsLeft]", Str(secondsLeft))

          Protected displayMessage.s = ReplaceString(baseMessage, "{COUNTDOWN}", Str(secondsLeft))
          displayMessage = ReplaceString(displayMessage, "[PopupSecondsLeft]", Str(secondsLeft))

          SetWindowTitle(hwnd, displayCaption)
          SetGadgetText(textGadgetID, displayMessage)

          AddWindowTimer(hwnd, 1, 1000)  ; Fire every 1 second for countdown
        EndIf
      Else
        ProcedureReturn 0
      EndIf

      Repeat
        Select WaitWindowEvent(10)
          Case #PB_Event_Gadget
            If EventGadget() = 100
              Break
            EndIf

          Case #PB_Event_CloseWindow
            Break

          Case #PB_Event_Timer
            If EventTimer() = 1
              Protected elapsed.i = (ElapsedMilliseconds() - startTime) / 1000
              secondsLeft = duration - elapsed

              If secondsLeft <= 0
                secondsLeft = 0
                SetNBVar("PopupSecondsLeft", "0")
                Break
              Else
                SetNBVar("PopupSecondsLeft", Str(secondsLeft))

                displayCaption = ReplaceString(baseCaption, "{COUNTDOWN}", Str(secondsLeft))
                displayCaption = ReplaceString(displayCaption, "[PopupSecondsLeft]", Str(secondsLeft))

                displayMessage = ReplaceString(baseMessage, "{COUNTDOWN}", Str(secondsLeft))
                displayMessage = ReplaceString(displayMessage, "[PopupSecondsLeft]", Str(secondsLeft))

                SetWindowTitle(hwnd, displayCaption)
                SetGadgetText(textGadgetID, displayMessage)
              EndIf
            EndIf
        EndSelect

        If g_nbWinHandle And Not IsWindow_(g_nbWinHandle)
          Break
        EndIf
      ForEver

      ; Cleanup timer and window
      If duration > 0 And IsWindow(hwnd)
        RemoveWindowTimer(hwnd, 1)
      EndIf

      If IsWindow(hwnd)
        CloseWindow(hwnd)
      EndIf

      ; Clear the countdown variable
      SetNBVar("PopupSecondsLeft", "")

      ; Call the callback subroutine if specified
      If Trim(callback) <> ""
        SetNBVar("PopupCallback", callback)
        CallNBSubroutine(callback)
      Else
        SetNBVar("PopupCallback", "")
      EndIf

  EndSelect

  ProcedureReturn 1
EndProcedure

; ------------------------------------------------------------
; Boilerplate functions - Keep simple like SDK template
; ------------------------------------------------------------
ProcedureDLL _nbRegisterInterfaceAccess(*Proc) : g_nbInterface = *Proc : EndProcedure
ProcedureDLL _nbRegisterScriptProcessor(*Proc) : g_nbPlayAction = *Proc : EndProcedure

; ------------------------------------------------------------
; _nbAbout - Display plugin information
; ------------------------------------------------------------
ProcedureDLL _nbAbout()
  MessageBox_(g_nbWinHandle, "Timer Message Plugin" + #CRLF$ + "by Brad Larned", "About Plugin", #MB_OK | #MB_ICONINFORMATION)
EndProcedure

; ------------------------------------------------------------
; _nbVerifyLicense - License verification (freeware)
; ------------------------------------------------------------
ProcedureDLL.i _nbVerifyLicense(*Code)
  ProcedureReturn #True  ; Return #True for freeware plugins
EndProcedure

; ------------------------------------------------------------
; _nbMessage
; ------------------------------------------------------------
ProcedureDLL _nbMessage(MsgCode.i, Reserved.i)
  ; Keep simple like ToneGen.pb and the working minimal skeleton
  ; No window cleanup needed - windows are closed in the event loop
EndProcedure

; ------------------------------------------------------------
; Helper: Call a subroutine in the publication
; ------------------------------------------------------------
Procedure CallNBSubroutine(subroutineName.s)
  If g_nbPlayAction
    Protected *cmd = MakeNBString("GoSub " + Chr(34) + subroutineName + Chr(34))
    If *cmd
      CallFunctionFast(g_nbPlayAction, *cmd)
      GlobalFree_(*cmd)
    EndIf
  EndIf
EndProcedure

; ============================================================
; DLL Lifecycle Management
; ============================================================
ProcedureDLL AttachProcess(Instance.i)
  ; Called when DLL is loaded - no initialization needed
EndProcedure

ProcedureDLL DetachProcess(Instance.i)
  ; Called when DLL is unloaded - free all global string allocations
  ; Note: Runtime Error 216 may still occur on VisualNEO Win IDE exit
  ; This is a known Delphi/PureBasic DLL unloading timing issue and is harmless
  If *g_PluginTitle  : GlobalFree_(*g_PluginTitle)  : *g_PluginTitle  = 0 : EndIf
  If *g_PluginAuthor : GlobalFree_(*g_PluginAuthor) : *g_PluginAuthor = 0 : EndIf
  If *g_PluginHint   : GlobalFree_(*g_PluginHint)   : *g_PluginHint   = 0 : EndIf
  If *g_ActionName   : GlobalFree_(*g_ActionName)   : *g_ActionName   = 0 : EndIf
  If *g_ActionHint   : GlobalFree_(*g_ActionHint)   : *g_ActionHint   = 0 : EndIf
EndProcedure

; IDE Options = PureBasic 6.21 (Windows - x86)
; ExecutableFormat = Shared dll
; Folding = ---
; EnableXP
; DPIAware
; Executable = TimerMsg.dll
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.21 (Windows - x86)