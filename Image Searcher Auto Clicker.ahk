#Persistent
#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

; Initialize variables
ClickingEnabled := 0
ImageFound := 0
SelectedImagePath := ""
ClickInterval := 250
ClickCount := 0
SearchRegionX1 := 0
SearchRegionY1 := 0
SearchRegionX2 := A_ScreenWidth
SearchRegionY2 := A_ScreenHeight
ShowSearchRegion := 0
ActiveHotkey := "F9"
Randomize := 0
StopWhenFound := 1

global IsProcessing := 0

DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, 16, 0)
NumPut(1, si, 0, "UInt")
DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &si, "Ptr", 0)

LoadSettings()

Gui, Font, s10, Arial
Gui, Add, Tab3, x5 y5 w460 h345 vCurrentTab gTabChanged, Main|Setup Guide|Credits

; === MAIN TAB ===
Gui, Tab, 1

; Image selection section
Gui, Add, GroupBox, x15 y35 w440 h80, Image Selection
Gui, Add, Button, x25 y55 w100 h25 gSelectImage, Select Image
Gui, Add, Button, x135 y55 w100 h25 gCaptureRegion, Capture Region
Gui, Add, Button, x245 y55 w120 h25 gTakeScreenshot, Take Screenshot
Gui, Add, Text, x25 y85 w80 h20, Current Image:

imagePath := "No image selected"
if (SelectedImagePath != "") {
    SplitPath, SelectedImagePath, imagePath
}
Gui, Add, Edit, x110 y85 w335 h20 vImagePathDisplay ReadOnly, %imagePath%

; Settings section
Gui, Add, GroupBox, x15 y125 w440 h80, Settings
Gui, Add, Text, x25 y145 w100 h20, Click Interval (ms):
Gui, Add, Edit, x130 y145 w60 h20 vClickIntervalInput, %ClickInterval%
Gui, Add, UpDown, Range50-5000, %ClickInterval%
Gui, Add, Checkbox, x210 y145 w150 h20 vRandomize Checked%Randomize%, Randomize interval
Gui, Add, Text, x25 y175 w100 h20, Click Counter:
Gui, Add, Text, x130 y175 w100 h20 vClickCounterDisplay, 0
Gui, Add, Checkbox, x210 y175 w240 h20 vStopWhenFound Checked%StopWhenFound%, Stop when image is found

; Controls section
Gui, Add, GroupBox, x15 y215 w440 h60, Controls
Gui, Add, Text, x25 y235 w60 h20, Hotkey:
Gui, Add, Hotkey, x90 y235 w100 h20 vUserHotkey, %ActiveHotkey%
Gui, Add, Button, x200 y235 w100 h30 gSetHotkey, Set Hotkey
Gui, Add, Checkbox, x310 y235 w140 h20 vShowRegion gToggleRegionDisplay Checked%ShowSearchRegion%, Show search area
Gui, Add, Button, x355 y280 w90 h30 gStartStopButton vStartStopButtonControl, Start (%ActiveHotkey%)

; Status section
Gui, Add, GroupBox, x15 y285 w330 h55, Status
Gui, Add, Text, x25 y305 w310 h25 vStatusText, Ready - Press %ActiveHotkey% to start/stop

; === SETUP GUIDE TAB ===
Gui, Tab, 2
Gui, Add, Text, x15 y35 w440 h25, How to Use This Image Searcher Auto Clicker:

Gui, Add, Edit, x15 y65 w440 h290 ReadOnly +WantReturn +VScroll, 
(
1. BASIC SETUP:
   * Set a hotkey or use the default F9 to start/stop clicking
   * Default click interval is 250ms (adjust as needed based on pc, if it passes the image you have set make the ms higher)

2. IMAGE DETECTION:
   * CAPTURE REGION: First select a search area on screen (no screenshot yet)
   * TAKE SCREENSHOT: Takes screenshot of the selected region (with the button)
   * SELECT IMAGE: Choose an existing .bmp file if needed
   * SHOW SEARCH AREA: Toggle visibility of the search region
  
3. WORKFLOW:
   * Step 1: Click "Capture Region" and select an area (it will be invisible just drag and click)
   * Step 2: Click "Take Screenshot" to capture that area
   * Step 3: Adjust options and click Start or press hotkey
   * The screenshot will be used for image detection

4. OPTIONS:
   * RANDOMIZE: Adds variation to click timing
   * STOP WHEN FOUND: Stops clicking after finding the image (recommended to have on for obvi reasons)

Settings are automatically saved when you change them.
Press your hotkey or click the Start button to begin.
)

; === CREDITS TAB ===
Gui, Tab, 3
Gui, Add, Text, x15 y35 w440 h25, Credits and Acknowledgements:
Gui, Add, Text, x15 y65 w440 h100, 
(
CREDITS:
- DC - skuxsaint: Helped with the api call for ImageSearch
- DC - 7_lz: Setup everything else along with claude to help with the UI functionality

Thank you for using the Image Searcher Auto Clicker!
)

Gui, Show, w500 h400, Image Searcher Auto Clicker

Hotkey, %ActiveHotkey%, ToggleScript, UseErrorLevel

FindBmpFiles()
return

TabChanged:
    Gui, Submit, NoHide
    if (CurrentTab = 1) {
        GuiControl,, StatusText, Ready - Press %ActiveHotkey% to start/stop
    }
return

FindBmpFiles() {
    global SelectedImagePath
    FileCount := 0
    
    Loop, %A_ScriptDir%\*.bmp {
        FileCount++
        if (FileCount = 1 && SelectedImagePath = "") {
            SelectedImagePath := A_LoopFilePath
            SplitPath, A_LoopFilePath, FileName
            GuiControl,, ImagePathDisplay, %FileName%
            GuiControl,, StatusText, Found image: %FileName%
        }
    }
    
    if (FileCount = 0 && SelectedImagePath = "") {
        GuiControl,, StatusText, No .bmp files found. Please select or capture an image.
    } else if (SelectedImagePath != "") {
        if (FileExist(SelectedImagePath)) {
            SplitPath, SelectedImagePath, FileName
            GuiControl,, ImagePathDisplay, %FileName%
            GuiControl,, StatusText, Loaded saved image: %FileName%
        } else {
            GuiControl,, StatusText, Saved image not found. Please select a new image.
            SelectedImagePath := ""
            GuiControl,, ImagePathDisplay, No image selected
        }
    }
    
    return FileCount
}

SelectImage:
    Gui +OwnDialogs
    FileSelectFile, SelectedFile, 3, %A_ScriptDir%, Select BMP Image, BMP Files (*.bmp)
    if (SelectedFile = "") {
        GuiControl,, StatusText, No image selected.
        return
    }
    
    SelectedImagePath := SelectedFile
    SplitPath, SelectedFile, FileName
    GuiControl,, ImagePathDisplay, %FileName%
    GuiControl,, StatusText, Image selected: %FileName%
    SaveSettings()
return

CaptureRegion:
    GuiControl,, StatusText, Click and drag to select region for capture and search...
    
    KeyWait, LButton, D
    MouseGetPos, startX, startY
    
    Gui, Selection:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Selection:Color, EEEEEE
    WinSet, Transparent, 80, Selection
    Gui, Selection:Show, x%startX% y%startY% w0 h0 NA
    
    Loop {
        Sleep, 10
        if !GetKeyState("LButton", "P") {
            break
        }
        
        MouseGetPos, currentX, currentY
        w := abs(currentX - startX)
        h := abs(currentY - startY)
        x := (currentX < startX) ? currentX : startX
        y := (currentY < startY) ? currentY : startY
        
        WinMove, Selection:, , %x%, %y%, %w%, %h%
    }
    
    MouseGetPos, endX, endY
    Gui, Selection:Destroy
    
    if (endX < startX) {
        temp := startX
        startX := endX
        endX := temp
    }
    
    if (endY < startY) {
        temp := startY
        startY := endY
        endY := temp
    }
    
    width := endX - startX
    height := endY - startY
    
    if (width < 5 || height < 5) {
        GuiControl,, StatusText, Region selection canceled - region too small
        return
    }
    
    SearchRegionX1 := startX
    SearchRegionY1 := startY
    SearchRegionX2 := endX
    SearchRegionY2 := endY
    
    GuiControl,, StatusText, Search area set. Click Take Screenshot to capture this region.
    UpdateRegionDisplay()
    SaveSettings()
return

TakeScreenshot:
    if (SearchRegionX2 > SearchRegionX1 && SearchRegionY2 > SearchRegionY1) {
        width := SearchRegionX2 - SearchRegionX1
        height := SearchRegionY2 - SearchRegionY1
        
        fileNum := 1
        Loop {
            screenshotFile := A_ScriptDir . "\new_screenshot" . fileNum . ".bmp"
            if !FileExist(screenshotFile)
                break
            fileNum++
        }
        
        CaptureScreen(SearchRegionX1, SearchRegionY1, width, height, screenshotFile)
        
        SelectedImagePath := screenshotFile
        SplitPath, screenshotFile, fileName
        GuiControl,, ImagePathDisplay, %fileName%
        GuiControl,, StatusText, Screenshot saved as %fileName% and set as current image.
        SaveSettings()
    } else {
        fileNum := 1
        Loop {
            screenshotFile := A_ScriptDir . "\new_screenshot" . fileNum . ".bmp"
            if !FileExist(screenshotFile)
                break
            fileNum++
        }
        
        CaptureScreen(0, 0, A_ScreenWidth, A_ScreenHeight, screenshotFile)
        
        SelectedImagePath := screenshotFile
        SplitPath, screenshotFile, fileName
        GuiControl,, ImagePathDisplay, %fileName%
        GuiControl,, StatusText, Full screen screenshot saved as %fileName% and set as current image.
        
        SearchRegionX1 := 0
        SearchRegionY1 := 0
        SearchRegionX2 := A_ScreenWidth
        SearchRegionY2 := A_ScreenHeight
        UpdateRegionDisplay()
        SaveSettings()
    }
return

CaptureScreen(x, y, w, h, filePath) {
    if (w < 1 || h < 1) {
        MsgBox, Error: Invalid capture dimensions
        return
    }
    
    hBitmap := DllCall("CreateCompatibleBitmap", "Ptr", DllCall("GetDC", "Ptr", 0), "Int", w, "Int", h, "Ptr")
    
    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    
    hOldBitmap := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBitmap, "Ptr")
    
    DllCall("BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcScreen, "Int", x, "Int", y, "UInt", 0x00CC0020) ; SRCCOPY
    
    hGdiPlus := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBitmap, "Ptr", 0, "Ptr*", pBitmap)
    
    VarSetCapacity(CLSID, 16)
    CLSIDFromString := DllCall("ole32\CLSIDFromString", "WStr", "{557CF400-1A04-11D3-9A73-0000F81EF32E}", "Ptr", &CLSID)
    
    saveResult := DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", filePath, "Ptr", &CLSID, "Ptr", 0)
    
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hOldBitmap)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    
    if (saveResult != 0) {
        MsgBox, Error saving screenshot (GDI+ error: %saveResult%)
        return 0
    }
    
    return filePath
}

ToggleRegionDisplay:
    Gui, Submit, NoHide
    ShowSearchRegion := ShowRegion
    
    if (ShowSearchRegion) {
        UpdateRegionDisplay()
    } else {
        Gui, SearchBox:Destroy
    }
    SaveSettings()
return

UpdateRegionDisplay() {
    global ShowSearchRegion, SearchRegionX1, SearchRegionY1, SearchRegionX2, SearchRegionY2
    
    if (!ShowSearchRegion)
        return
    
    Gui, SearchBox:Destroy
    
    width := SearchRegionX2 - SearchRegionX1
    height := SearchRegionY2 - SearchRegionY1
    
    Gui, SearchBox:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, SearchBox:Color, FF0000
    WinSet, Transparent, 30, SearchBox
    Gui, SearchBox:Show, x%SearchRegionX1% y%SearchRegionY1% w%width% h%height% NA
}

StartStopButton:
    Gosub, ToggleScript
return

SetHotkey:
    Gui, Submit, NoHide
    if (UserHotkey = "") {
        GuiControl,, StatusText, Please specify a hotkey first.
        return
    }
    
    Hotkey, %ActiveHotkey%, ToggleScript, Off
    
    ActiveHotkey := UserHotkey
    Hotkey, %ActiveHotkey%, ToggleScript, UseErrorLevel
    if (ErrorLevel) {
        MsgBox, 16, Hotkey Error, Could not register %ActiveHotkey% hotkey.`nTry running as administrator or using a different key.
        GuiControl,, StatusText, Error: Could not register %ActiveHotkey% hotkey.
    } else {
        GuiControl,, StatusText, Hotkey set to %ActiveHotkey%
        GuiControl,, StartStopButtonControl, Start (%ActiveHotkey%)
        SaveSettings()
    }
return

ToggleScript:
    global ClickingEnabled, ImageFound, ClickCount, ClickInterval
    ClickingEnabled := !ClickingEnabled
    ImageFound := 0
    
    Gui, Submit, NoHide
    ClickInterval := ClickIntervalInput
    
    if (ClickingEnabled) {
        if (SelectedImagePath = "") {
            MsgBox, Please select an image first!
            ClickingEnabled := 0
            return
        }
        
        if !FileExist(SelectedImagePath) {
            MsgBox, 16, Error, Image file not found:`n%SelectedImagePath%`n`nPlease select a valid image.
            ClickingEnabled := 0
            return
        }
        
        CoordMode, Pixel, Screen
        
        GuiControl,, StatusText, Testing image search...
        ImageSearch, testX, testY, SearchRegionX1, SearchRegionY1, SearchRegionX2, SearchRegionY2, *40 %SelectedImagePath%
        
        if (ErrorLevel = 2) {
            MsgBox, 16, Error, Image search failed. Possible causes:`n- Invalid or corrupt image file`n- Search region too large`n- System resources issue`n`nTry using Capture Region to create a new search image.
            ClickingEnabled := 0
            return
        }
        
        SetTimer, ClickLoop, %ClickInterval%
        GuiControl,, StatusText, Auto-Clicker ON - Looking for image...
        GuiControl,, StartStopButtonControl, Stop (%ActiveHotkey%)
    } else {
        SetTimer, ClickLoop, Off
        GuiControl,, StatusText, Auto-Clicker OFF
        GuiControl,, StartStopButtonControl, Start (%ActiveHotkey%)
    }
    SaveSettings()
return
global IsProcessing := 0

ClickLoop:
    global ClickingEnabled, ImageFound, ClickCount, ClickInterval
    global SearchRegionX1, SearchRegionY1, SearchRegionX2, SearchRegionY2
    global IsProcessing
    
    if (IsProcessing)
        return
        
    IsProcessing := 1
    
    Gui, Submit, NoHide
    
    if !FileExist(SelectedImagePath) {
        GuiControl,, StatusText, Error: Image file not found
        SetTimer, ClickLoop, Off
        ClickingEnabled := 0
        GuiControl,, StartStopButtonControl, Start (%ActiveHotkey%)
        IsProcessing := 0
        return
    }
    
    if (SearchRegionX1 < 0 || SearchRegionY1 < 0 || SearchRegionX2 > A_ScreenWidth || SearchRegionY2 > A_ScreenHeight) {
        GuiControl,, StatusText, Error: Invalid search region coordinates
        IsProcessing := 0
        return
    }
    
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen
    
    ImageSearch, FoundX, FoundY, SearchRegionX1, SearchRegionY1, SearchRegionX2, SearchRegionY2, *40 %SelectedImagePath%
    
    if (ErrorLevel = 0) {
        MouseMove, FoundX, FoundY
        Click
        ClickCount++
        GuiControl,, ClickCounterDisplay, %ClickCount%
        GuiControl,, StatusText, Image found! Clicked at %FoundX%, %FoundY%
        
        if (StopWhenFound) {
            ImageFound := 1
            SetTimer, ClickLoop, Off
            ClickingEnabled := 0
            GuiControl,, StartStopButtonControl, Start (%ActiveHotkey%)
            IsProcessing := 0
            return
        }
    } else if (ErrorLevel = 1) {
        Click
        ClickCount++
        GuiControl,, ClickCounterDisplay, %ClickCount%
        GuiControl,, StatusText, Image not found. Clicking at current position.
    } else {
        GuiControl,, StatusText, Error searching for image (code: %ErrorLevel%). Check file format.
        Sleep, 1000
    }
    
    if (Randomize) {
        randomizedInterval := ClickInterval + Random(-ClickInterval/5, ClickInterval/5)
        SetTimer, ClickLoop, %randomizedInterval%
    }
    
    IsProcessing := 0
return

Random(min, max) {
    Random, output, min, max
    return output
}

SaveSettings() {
    global ClickInterval, ActiveHotkey, SelectedImagePath
    global SearchRegionX1, SearchRegionY1, SearchRegionX2, SearchRegionY2, ShowSearchRegion
    global Randomize, StopWhenFound
    
    ; Main settings
    IniWrite, %ClickInterval%, %A_ScriptDir%\settings.ini, Settings, ClickInterval
    IniWrite, %ActiveHotkey%, %A_ScriptDir%\settings.ini, Settings, ActiveHotkey
    IniWrite, %SelectedImagePath%, %A_ScriptDir%\settings.ini, Settings, SelectedImagePath
    
    ; Search region
    IniWrite, %SearchRegionX1%, %A_ScriptDir%\settings.ini, Region, SearchRegionX1
    IniWrite, %SearchRegionY1%, %A_ScriptDir%\settings.ini, Region, SearchRegionY1
    IniWrite, %SearchRegionX2%, %A_ScriptDir%\settings.ini, Region, SearchRegionX2
    IniWrite, %SearchRegionY2%, %A_ScriptDir%\settings.ini, Region, SearchRegionY2
    IniWrite, %ShowSearchRegion%, %A_ScriptDir%\settings.ini, Region, ShowSearchRegion
    
    ; Options
    IniWrite, %Randomize%, %A_ScriptDir%\settings.ini, Options, Randomize
    IniWrite, %StopWhenFound%, %A_ScriptDir%\settings.ini, Options, StopWhenFound
}

LoadSettings() {
    global ClickInterval, ActiveHotkey, SelectedImagePath
    global SearchRegionX1, SearchRegionY1, SearchRegionX2, SearchRegionY2, ShowSearchRegion
    global Randomize, StopWhenFound
    
    if FileExist(A_ScriptDir . "\settings.ini") {
        ; Main settings
        IniRead, ClickInterval, %A_ScriptDir%\settings.ini, Settings, ClickInterval, 200
        IniRead, ActiveHotkey, %A_ScriptDir%\settings.ini, Settings, ActiveHotkey, F9
        IniRead, SelectedImagePath, %A_ScriptDir%\settings.ini, Settings, SelectedImagePath, 
        
        ; Search region
        IniRead, SearchRegionX1, %A_ScriptDir%\settings.ini, Region, SearchRegionX1, 0
        IniRead, SearchRegionY1, %A_ScriptDir%\settings.ini, Region, SearchRegionY1, 0
        IniRead, SearchRegionX2, %A_ScriptDir%\settings.ini, Region, SearchRegionX2, %A_ScreenWidth%
        IniRead, SearchRegionY2, %A_ScriptDir%\settings.ini, Region, SearchRegionY2, %A_ScreenHeight%
        IniRead, ShowSearchRegion, %A_ScriptDir%\settings.ini, Region, ShowSearchRegion, 0
        
        ; Options
        IniRead, Randomize, %A_ScriptDir%\settings.ini, Options, Randomize, 0
        IniRead, StopWhenFound, %A_ScriptDir%\settings.ini, Options, StopWhenFound, 0
    }
}

GuiClose:
    SaveSettings()
    
    DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
    Gui, SearchBox:Destroy
    ExitApp
return
