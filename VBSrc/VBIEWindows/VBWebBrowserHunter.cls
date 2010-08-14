VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CVBWebBrowserHunter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'***********************************************************************************************************************
'
'ģ �� ��: CVBWebBrowserHunter
'
'��    ��: Supergreenbean
'
'��������: ͨ��ָ��Shell Embedding��(MS WebBrowser�ؼ�)���ھ��������������
'
'��    ��: 2005��05��22��
'
'ʹ��˵��:
'       1.��ýӿڶ���
'           ��:
'               ����Ŀ�괰�ھ��Ϊ&H5180
'
'               ���õ����������
'                   m_oWBHunter.GetBrowser(&H5180)
'
'                   Set m_oIE = m_oWBHunter.IEObject
'***********************************************************************************************************************
'
Option Explicit
'��ģ������
Private Const THIS_MODULE_NAME As String = "CVBWebBrowserHunter"

'=======================================================================================================================
'����ΪWindows API�������
'=======================================================================================================================
Private Declare Function GetCurrentProcessId Lib "kernel32" () As Long
Private Declare Function OpenProcess Lib "kernel32" (ByVal dwDesiredAccess As Long, ByVal bInheritHandle As Long, ByVal dwProcessId As Long) As Long
Private Declare Function CloseHandle Lib "kernel32" (ByVal hObject As Long) As Long

Private Const PROCESS_ALL_ACCESS = &H1F0FFF

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)

Private Declare Function VirtualProtectEx Lib "kernel32" (ByVal hProcess As Long, lAddress As Any, ByVal dwSize As Long, ByVal flNewProtect As Long, lpflOldProtect As Long) As Long
Private Declare Function VirtualQueryEx Lib "kernel32" (ByVal hProcess As Long, lpAddress As Any, lpBuffer As MEMORY_BASIC_INFORMATION, ByVal dwLength As Long) As Long
Private Type MEMORY_BASIC_INFORMATION
     BaseAddress As Long
     AllocationBase As Long
     AllocationProtect As Long
     RegionSize As Long
     State As Long
     Protect As Long
     lType As Long
End Type

Private Const PAGE_READWRITE As Long = &H4

Private Declare Function ReadProcessMemory Lib "kernel32" (ByVal hProcess As Long, lpBaseAddress As Any, lpBuffer As Any, ByVal nSize As Long, lpNumberOfBytesWritten As Long) As Long
Private Declare Function WriteProcessMemory Lib "kernel32" (ByVal hProcess As Long, lpBaseAddress As Any, lpBuffer As Any, ByVal nSize As Long, lpNumberOfBytesWritten As Long) As Long

Private Declare Function GetWindowThreadProcessId Lib "user32" (ByVal hwnd As Long, lpdwProcessId As Long) As Long

Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Private Declare Function PostMessage Lib "user32" Alias "PostMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long

Private Const WM_USER = &H400
Private Const WM_GETSHELLBROWSER = WM_USER + 7

Private Declare Function GlobalAlloc Lib "kernel32" (ByVal wFlags As Long, ByVal dwBytes As Long) As Long
Private Declare Function GlobalFree Lib "kernel32" (ByVal hMem As Long) As Long
Private Declare Function GlobalLock Lib "kernel32" (ByVal hMem As Long) As Long
Private Declare Function GlobalUnlock Lib "kernel32" (ByVal hMem As Long) As Long
Private Const GMEM_MOVEABLE = &H2

Private Declare Function CreateStreamOnHGlobal Lib "ole32" (ByVal hGlobal As Long, ByVal fDeleteOnRelease As Long, ppstm As Long) As Long
Private Declare Function CoUnmarshalInterface Lib "ole32" (ByVal pStm As Long, riid As GUID, ppv As Object) As Long

Private Declare Function IIDFromString Lib "ole32" (ByVal lpsz As Long, ByRef lpiid As GUID) As Long

Private Declare Function SuspendThread Lib "kernel32" (ByVal hThread As Long) As Long
Private Declare Function ResumeThread Lib "kernel32" (ByVal hThread As Long) As Long
Private Declare Function FlushInstructionCache Lib "kernel32" (ByVal hProcess As Long, lpBaseAddress As Any, ByVal dwSize As Long) As Long
Private Declare Function GetThreadContext Lib "kernel32" (ByVal hThread As Long, lpContext As CONTEXT) As Long
Private Declare Function SetThreadContext Lib "kernel32" (ByVal hThread As Long, lpContext As CONTEXT) As Long

Private Declare Function OpenThread Lib "kernel32" (ByVal dwDesiredAccess As Long, ByVal bInheritHandle As Long, ByVal dwThreadId As Long) As Long

Private Const THREAD_ALL_ACCESS = &H1F03FF


Private Const CONTEXT_FULL As Long = &H10007

Private Const SIZE_OF_80387_REGISTERS = 80&

Private Const MAXIMUM_SUPPORTED_EXTENSION = 512&

Private Type FLOATING_SAVE_AREA
    ControlWord As Long
    StatusWord As Long
    TagWord As Long
    ErrorOffset As Long
    ErrorSelector As Long
    DataOffset As Long
    DataSelector As Long
    RegisterArea(SIZE_OF_80387_REGISTERS - 1) As Byte
    Cr0NpxState As Long
End Type

Private Type CONTEXT
    ContextFlags As Long
    Dr0 As Long
    Dr1 As Long
    Dr2 As Long
    Dr3 As Long
    Dr6 As Long
    Dr7 As Long
    FloatSave As FLOATING_SAVE_AREA
    SegGs As Long
    SegFs As Long
    SegEs As Long
    SegDs As Long
    Edi As Long
    Esi As Long
    Ebx As Long
    Edx As Long
    Ecx As Long
    Eax As Long
    Ebp As Long
    EIP As Long
    SegCs As Long
    EFlags As Long
    Esp As Long
    SegSs As Long
    ExtendedRegisters(MAXIMUM_SUPPORTED_EXTENSION - 1) As Byte
End Type

Private Type GUID
  Data1 As Long
  Data2 As Integer
  Data3 As Integer
  Data4(7) As Byte
End Type
'=======================================================================================================================
'����ΪWindows API�������
'=======================================================================================================================

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'=======================================================================================================================
'����Ϊ���ڲ�˽�б���
'=======================================================================================================================
'lpStart��Ŀ��������������ڴ����ʼ��ַ
Private Type FUNCTION_TABLE
    'lpStart + 0
    lpCoGetMarshalSizeMax As Long
    'lpStart + 4
    lpCoMarshalInterface As Long
    'lpStart + 8
    lpCreateStreamOnHGlobal As Long
    'lpStart + C
    lpGlobalAlloc As Long
    'lpStart + 10
    lpGlobalFree As Long
    'lpStart + 14
    lpGlobalLock As Long
    'lpStart + 18
    lpGlobalUnlock As Long
End Type

Private Type GUIDS
    'lpStart + 1C
    IID_IServiceProvider As GUID
    'lpStart + 2C
    SID_STopLevelBrowser As GUID
    'lpStart + 3C
    IID_IWebBrowserApp As GUID
    'lpStart + 4C
    IID_IWebBrowser2 As GUID
End Type

Private Type Variables
    tFunctionTable As FUNCTION_TABLE
    tGuids As GUIDS
    'lpStart + 5C
    cbData As Long
    'lpStart + 60
    lpData As Long
    'lpStart + 64
    lpShellBrowser As Long
    'lpStart + 68
    BreakFlag As Long
    'lpStart + 6C
    Reserved As Long
    'lpStart + 70
    abCodeBuffer(511) As Byte
End Type

'����
Private m_tVariables As Variables

'Ŀ��������������ڴ����ʼ��ַ
Private m_lpStartAddress As Long

'Ŀ����̵Ľ��̾��
Private m_lhProcess As Long

'�ڴ�����������
Private m_oMemAllocator As CVBMemoryAllocator

'WB����
Private m_oIEObject As Object
'=======================================================================================================================
'����Ϊ���ڲ�˽�б���
'=======================================================================================================================

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'=======================================================================================================================
'����Ϊ������
'=======================================================================================================================
'�õ�ָ�������������
Public Property Get IEObject() As Object
    Set IEObject = m_oIEObject
End Property
'=======================================================================================================================
'����Ϊ������
'=======================================================================================================================

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'=======================================================================================================================
'����Ϊ�๫�к���
'=======================================================================================================================
'������������
Public Function GetBrowser(ByVal hTargetWnd As Long) As Boolean
    On Error GoTo CleanUp
    
    Dim tid As Long, pid As Long
    
    Set m_oIEObject = Nothing
    
    Set m_oMemAllocator = Nothing
    
    With m_tVariables
        .cbData = 0
        .lpData = 0
        .lpShellBrowser = GetShellBrowserPointer(hTargetWnd)
        .BreakFlag = 0
        .Reserved = 0
        Erase .abCodeBuffer
        
        If .lpShellBrowser = 0 Then Exit Function
    End With
    
    tid = GetWindowThreadProcessId(hTargetWnd, pid)
    
    If pid = 0 Then Exit Function
    
    m_lhProcess = OpenProcess(PROCESS_ALL_ACCESS, 0&, pid)
    
    If m_lhProcess = 0 Then Exit Function
    
    Dim hThread As Long
    
    hThread = OpenThread(THREAD_ALL_ACCESS, 0, tid)
    
    If hThread = 0 Then ErrExit
    
    If InitGUIDs And InitFunctionTable(pid) Then
    
        Set m_oMemAllocator = New CVBMemoryAllocator
        
        m_oMemAllocator.Allocate Len(m_tVariables), m_lpStartAddress, pid, True
        
        If m_lpStartAddress = 0 Then ErrExit
            
        Dim tContext As CONTEXT
        
        If SuspendThread(hThread) = -1 Then ErrExit
        
        tContext.ContextFlags = CONTEXT_FULL
        
        Call GetThreadContext(hThread, tContext)
        
        If Not PrepareStub(tContext.EIP) Then ErrExit
        
        tContext.EIP = m_lpStartAddress + &H70
        
        Call FlushInstructionCache(m_lhProcess, ByVal tContext.EIP, UBound(m_tVariables.abCodeBuffer) + 1)
        
        If SetThreadContext(hThread, tContext) = 0 Then ErrExit
        
        If ResumeThread(hThread) = -1 Then ErrExit
        
        PostMessage hTargetWnd, 0, 0, ByVal 0
        
        Dim lBreakFlag As Long
        
        Do While lBreakFlag = 0
            memcpy2local VarPtr(lBreakFlag), m_lpStartAddress + &H68, 4
            DoEvents
        Loop
        
        If lBreakFlag = 1 Then
            Dim lpObjData As Long, lDataSize As Long
            memcpy2local VarPtr(lpObjData), m_lpStartAddress + &H60, 4
            memcpy2local VarPtr(lDataSize), m_lpStartAddress + &H5C, 4
            
            GetBrowser = UnmarshalInterface(lpObjData, lDataSize)
            
            lBreakFlag = 0
            memcpy2remote m_lpStartAddress + &H68, VarPtr(lBreakFlag), 4
        End If
    End If
CleanUp:
    CloseHandle hThread
    CloseHandle m_lhProcess
End Function
'=======================================================================================================================
'����Ϊ�๫������
'=======================================================================================================================

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'=======================================================================================================================
'����Ϊ�ڲ�����
'=======================================================================================================================
'���Ŀ�괰�ڵ�IShellBrowserָ��
Private Function GetShellBrowserPointer(ByVal hTargetWnd As Long) As Long
    GetShellBrowserPointer = SendMessage(hTargetWnd, WM_GETSHELLBROWSER, 0, ByVal 0)
End Function

'׼������Ŀ�괰�ڽ�����ִ�еĴ���
Private Function PrepareStub(ByVal lRetEIP As Long) As Boolean
    On Error GoTo Error_Handler
    Dim sCodes As String
    
    sCodes = ""
    
    'int 3
    'sCodes = "CC "
    
    sCodes = sCodes & "60 9C 8B EC 83 EC 30 BB " & LongToByteCodeStr(m_lpStartAddress) & "8D 7D F8 57 8D "
    sCodes = sCodes & "7B 1C 57 8B 43 64 8B 08 50 FF 11 83 F8 00 0F 8C DB "
    sCodes = sCodes & "00 00 00 8D 7D F4 57 8D 7B 1C 57 8D 7B 2C 57 8B 45 "
    sCodes = sCodes & "F8 8B 08 50 FF 51 0C 83 F8 00 0F 8C AB 00 00 00 8D "
    sCodes = sCodes & "7D F0 57 8D 7B 4C 57 8D 7B 3C 57 8B 45 F8 8B 08 50 "
    sCodes = sCodes & "FF 51 0C 83 F8 00 0F 8C 84 00 00 00 6A 00 6A 00 6A "
    sCodes = sCodes & "00 FF 75 F0 8D 7B 4C 57 8D 7D EC 57 FF 13 83 F8 00 "
    sCodes = sCodes & "0F 8C 83 00 00 00 8D 7D EC 57 6A 02 FF 53 0C 83 F8 "
    sCodes = sCodes & "00 74 75 8D 4D E8 89 01 8D 7D E4 57 6A 01 8B 7D E8 "
    sCodes = sCodes & "57 FF 53 08 83 F8 00 7D 09 8B 7D E8 57 FF 53 10 EB "
    sCodes = sCodes & "3A 6A 00 6A 00 6A 00 FF 75 F0 8D 7B 4C 57 FF 75 E4 "
    sCodes = sCodes & "FF 53 04 83 F8 00 7C 34 8D 7B 5C 8D 75 EC A5 8B 7D "
    sCodes = sCodes & "E8 57 FF 53 14 89 43 60 8B 7D E8 57 FF 53 18 C6 43 "
    sCodes = sCodes & "68 01 83 7B 68 00 75 FA 8B 45 F4 8B 08 50 FF 51 08 "
    sCodes = sCodes & "8B 45 F8 8B 08 50 FF 51 08 8B 45 E4 8B 08 50 FF 51 "
    sCodes = sCodes & "08 C6 43 68 02 8B E5 9D 61 68 " & LongToByteCodeStr(lRetEIP) & "C3"
    Dim abCodes() As Byte
    abCodes = ByteCodeStrToBin(sCodes)
    
    If UBound(abCodes) <= UBound(m_tVariables.abCodeBuffer) Then
        CopyMemory m_tVariables.abCodeBuffer(0), abCodes(0), UBound(abCodes) + 1

        PrepareStub = memcpy2remote(m_lpStartAddress, VarPtr(m_tVariables), Len(m_tVariables))
    Else
        PrepareStub = False
    End If
    
    Exit Function
Error_Handler:
End Function

'�����������ڴ����ݸ��Ƶ��������ڴ�
Private Function memcpy2local(ByVal lpDestAddr As Long, ByVal lpSrcAddr As Long, ByVal lLen As Long) As Boolean
    On Error GoTo Error_Handler
    Dim lOldProtect As Long
    Dim lBytesReadWrite As Long
    
    If m_lhProcess Then
        If VirtualProtectEx(m_lhProcess, ByVal lpSrcAddr, lLen, PAGE_READWRITE, lOldProtect) <> 0 Then
            ReadProcessMemory m_lhProcess, ByVal lpSrcAddr, ByVal lpDestAddr, lLen, lBytesReadWrite
            Call VirtualProtectEx(m_lhProcess, ByVal lpSrcAddr, lLen, lOldProtect, lOldProtect)
            memcpy2local = (lBytesReadWrite <> 0)
        End If
    End If
    Exit Function
Error_Handler:
End Function

'�ѱ����ڴ����ݸ��Ƶ������������ڴ�
Private Function memcpy2remote(ByVal lpDestAddr As Long, ByVal lpSrcAddr As Long, ByVal lLen As Long) As Boolean
    On Error GoTo Error_Handler
    Dim lOldProtect As Long
    Dim lBytesReadWrite As Long
    
    If m_lhProcess Then
        If VirtualProtectEx(m_lhProcess, ByVal lpDestAddr, lLen, PAGE_READWRITE, lOldProtect) <> 0 Then
            WriteProcessMemory m_lhProcess, ByVal lpDestAddr, ByVal lpSrcAddr, lLen, lBytesReadWrite
            Call VirtualProtectEx(m_lhProcess, ByVal lpDestAddr, lLen, lOldProtect, lOldProtect)
            memcpy2remote = (lBytesReadWrite <> 0)
        End If
    End If
    Exit Function
Error_Handler:
End Function

'16�����ַ�����Ϊ�ֽ�����
Private Function ByteCodeStrToBin(ByVal sByteCode As String) As Byte()
    Dim s() As String
    Dim b() As Byte
    Dim i As Long
    
    s = Split(Trim(sByteCode), " ")
    
    If UBound(s) >= 0 Then
        ReDim b(UBound(s))
    End If
    
    For i = 0 To UBound(s)
        b(i) = CByte("&h" & s(i))
    Next
    ByteCodeStrToBin = b
End Function

'�����ͱ�Ϊ16�����ַ���
Private Function LongToByteCodeStr(ByVal lValue As Long) As String
    Dim s As String
    s = Right$("00000000" & Hex(lValue), 8)
    LongToByteCodeStr = Mid$(s, 1, 2) & " " & LongToByteCodeStr
    LongToByteCodeStr = Mid$(s, 3, 2) & " " & LongToByteCodeStr
    LongToByteCodeStr = Mid$(s, 5, 2) & " " & LongToByteCodeStr
    LongToByteCodeStr = Mid$(s, 7, 2) & " " & LongToByteCodeStr
End Function

'�����Զ������
Private Sub ErrExit()
    Err.Raise vbObjectError + &H1122
End Sub

'��ʼ��GUID
Private Function InitGUIDs() As Boolean
    With m_tVariables.tGuids
        If IIDFromString(StrPtr("{6D5140C1-7436-11CE-8034-00AA006009FA}"), .IID_IServiceProvider) < 0 Then Exit Function
        If IIDFromString(StrPtr("{D30C1661-CDAF-11d0-8A3E-00C04FC9E26E}"), .IID_IWebBrowser2) < 0 Then Exit Function
        If IIDFromString(StrPtr("{0002DF05-0000-0000-C000-000000000046}"), .IID_IWebBrowserApp) < 0 Then Exit Function
        If IIDFromString(StrPtr("{4C96BE40-915C-11CF-99D3-00AA004AE837}"), .SID_STopLevelBrowser) < 0 Then Exit Function
    End With
    
    InitGUIDs = True
End Function

'��ʼ��������
Private Function InitFunctionTable(ByVal pid As Long) As Boolean
    Dim oPEFnLocator As CVBPEFnLocator
    Set oPEFnLocator = New CVBPEFnLocator
    
    With oPEFnLocator
        .SetTargetTo pid
        
        If Not .LocateExportFunction("ole32.dll", "CoGetMarshalSizeMax") Then Exit Function
        m_tVariables.tFunctionTable.lpCoGetMarshalSizeMax = .ExpJumpAddress
        
        If Not .LocateExportFunction("ole32.dll", "CoMarshalInterface") Then Exit Function
        m_tVariables.tFunctionTable.lpCoMarshalInterface = .ExpJumpAddress
        
        If Not .LocateExportFunction("ole32.dll", "CreateStreamOnHGlobal") Then Exit Function
        m_tVariables.tFunctionTable.lpCreateStreamOnHGlobal = .ExpJumpAddress
        
        If Not .LocateExportFunction("kernel32.dll", "GlobalAlloc") Then Exit Function
        m_tVariables.tFunctionTable.lpGlobalAlloc = .ExpJumpAddress
        
        If Not .LocateExportFunction("kernel32.dll", "GlobalFree") Then Exit Function
        m_tVariables.tFunctionTable.lpGlobalFree = .ExpJumpAddress
        
        If Not .LocateExportFunction("kernel32.dll", "GlobalLock") Then Exit Function
        m_tVariables.tFunctionTable.lpGlobalLock = .ExpJumpAddress
        
        If Not .LocateExportFunction("kernel32.dll", "GlobalUnlock") Then Exit Function
        m_tVariables.tFunctionTable.lpGlobalUnlock = .ExpJumpAddress
        
        If Not .LocateExportFunction("kernel32.dll", "GlobalUnlock") Then Exit Function
        m_tVariables.tFunctionTable.lpGlobalUnlock = .ExpJumpAddress
    End With
        
    InitFunctionTable = True
End Function

'�ͷ�IStream����
Private Function ReleaseStream(ByVal lpStream As Long) As Boolean
    Dim lpThis As Long
    Dim lpVTable As Long
    
    Dim oTmp As Collection
    
    If lpStream = 0 Then Exit Function
    
    Set oTmp = New Collection
    
    lpThis = ObjPtr(oTmp)
    
    CopyMemory lpVTable, ByVal lpThis, 4
    
    CopyMemory ByVal lpThis, ByVal lpStream, 4
    Set oTmp = Nothing
    CopyMemory ByVal lpThis, lpVTable, 4
    
    Set oTmp = Nothing
    ReleaseStream = True
End Function

'ɢ�����������
Private Function UnmarshalInterface(ByVal lpObjData As Long, ByVal lDataSize As Long) As Boolean
    Dim hGlobal As Long
    hGlobal = GlobalAlloc(GMEM_MOVEABLE, lDataSize)
    
    If hGlobal = 0 Then Exit Function
    
    Dim lpData As Long
    lpData = GlobalLock(hGlobal)
    memcpy2local lpData, lpObjData, lDataSize
    GlobalUnlock hGlobal
    
    Dim lpStream As Long
    Dim hr As Long
    
    hr = CreateStreamOnHGlobal(hGlobal, 1, lpStream)
    
    If hr < 0 Then
        GlobalFree hGlobal
        Exit Function
    End If
    
    hr = CoUnmarshalInterface(lpStream, m_tVariables.tGuids.IID_IWebBrowser2, m_oIEObject)
    
    If hr < 0 Then
        GlobalFree hGlobal
        ReleaseStream lpStream
        Exit Function
    End If
    
    ReleaseStream lpStream
    
    UnmarshalInterface = True
End Function
'=======================================================================================================================
'����Ϊ�ڲ�����
'=======================================================================================================================

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'=======================================================================================================================
'����Ϊ���ʼ�������ٹ���
'=======================================================================================================================
'=======================================================================================================================
'����Ϊ���ʼ�������ٹ���
'=======================================================================================================================