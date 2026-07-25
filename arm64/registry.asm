REGISTRY_ASM EQU 1

    INCLUDE data.inc
    INCLUDE proto.inc

    EXPORT SavePlayerName
    EXPORT LoadPlayerName
    EXPORT SaveHighScore
    EXPORT LoadHighScore
    EXPORT ClearRegistry

; ---------------------------------------------------------------------------
; Read-only data - Unicode (UTF-16) registry strings
; ---------------------------------------------------------------------------
    AREA |.rdata|, DATA, READONLY, ALIGN=4
    ALIGN 4

reg_szRegPath       DCW 'S','o','f','t','w','a','r','e',92,'T','e','t','r','i','s',0
reg_szPlayerName    DCW 'P','l','a','y','e','r','N','a','m','e',0
reg_szHighScore     DCW 'H','i','g','h','S','c','o','r','e',0
reg_szHighScoreName DCW 'H','i','g','h','S','c','o','r','e','N','a','m','e',0

; ---------------------------------------------------------------------------
; Code
; ---------------------------------------------------------------------------
    AREA |.text|, CODE, READONLY, ALIGN=4
    ALIGN 16

; ---------------------------------------------------------------------------
; StrLenW - local helper
; X0 = wide string
; Returns W0 = length in characters
; ---------------------------------------------------------------------------
StrLenW PROC
    MOV W1, #0
    CBZ X0, slw_done

slw_loop
    LSL X2, X1, #1
    LDRH W2, [X0, X2]
    CBZ W2, slw_done
    ADD W1, W1, #1
    B slw_loop

slw_done
    MOV W0, W1
    RET
    ENDP

; ---------------------------------------------------------------------------
; SavePlayerName
; X0 = pName (UTF-16)
; Returns W0 = 1 on success, 0 on failure
; ---------------------------------------------------------------------------
SPN_FRAME  EQU 0x80
SPN_FP     EQU 0x70
SPN_SAVE   EQU 0x60
SPN_HKEY   EQU 0x40
SPN_SIZE   EQU 0x48
SPN_RESULT EQU 0x4C

SavePlayerName PROC
    SUB SP, SP, #SPN_FRAME
    STP X29, X30, [SP, #SPN_FP]
    ADD X29, SP, #SPN_FP
    STP X19, X20, [SP, #SPN_SAVE]

    MOV X19, X0

    ; RegCreateKeyExW(HKCU, "Software\Tetris", 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL)
    ; X0..X7 = args 1..8, [SP,#0] = arg 9
    MOVZ W0, #0x0001
    MOVK W0, #0x8000, LSL #16    ; arg 1: HKEY_CURRENT_USER
    LDR X1, =reg_szRegPath       ; arg 2: lpSubKey
    MOV X2, #0                   ; arg 3: Reserved
    MOV X3, #0                   ; arg 4: lpClass
    MOV X4, #0                   ; arg 5: dwOptions
    MOVZ W5, #0x0006
    MOVK W5, #0x0002, LSL #16    ; arg 6: KEY_WRITE = 0x20006
    MOV X6, #0                   ; arg 7: lpSecurityAttributes
    ADD X7, SP, #SPN_HKEY        ; arg 8: phkResult
    STR XZR, [SP, #0]            ; arg 9: lpdwDisposition

    BL RegCreateKeyExW
    CBNZ W0, spn_fail

    ; Byte size = (strlen(pName) + 1) * 2
    MOV X0, X19
    BL StrLenW
    ADD W0, W0, #1
    LSL W0, W0, #1
    STR W0, [SP, #SPN_SIZE]

    ; RegSetValueExW(hKey, "PlayerName", 0, REG_SZ, pName, size)
    ; X0..X5 = args 1..6
    LDR X0, [SP, #SPN_HKEY]      ; arg 1: hKey
    LDR X1, =reg_szPlayerName    ; arg 2: lpValueName
    MOV X2, #0                   ; arg 3: Reserved
    MOV X3, #1                   ; arg 4: REG_SZ
    MOV X4, X19                  ; arg 5: lpData
    LDR W5, [SP, #SPN_SIZE]      ; arg 6: cbData

    BL RegSetValueExW
    STR W0, [SP, #SPN_RESULT]

    LDR X0, [SP, #SPN_HKEY]
    BL RegCloseKey

    LDR W0, [SP, #SPN_RESULT]
    CBNZ W0, spn_fail

    MOV W0, #1
    B spn_exit

spn_fail
    MOV W0, #0

spn_exit
    LDP X19, X20, [SP, #SPN_SAVE]
    LDP X29, X30, [SP, #SPN_FP]
    ADD SP, SP, #SPN_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; LoadPlayerName
; X0 = pGame
; Returns W0 = 1 if loaded, 0 if not found
; ---------------------------------------------------------------------------
LPN_FRAME  EQU 0x180
LPN_FP     EQU 0x170
LPN_SAVE   EQU 0x160
LPN_BUF    EQU 0x40
LPN_HKEY   EQU 0x140
LPN_SIZE   EQU 0x148
LPN_TYPE   EQU 0x14C
LPN_RESULT EQU 0x150

LoadPlayerName PROC
    SUB SP, SP, #LPN_FRAME
    STP X29, X30, [SP, #LPN_FP]
    ADD X29, SP, #LPN_FP
    STP X19, X20, [SP, #LPN_SAVE]

    MOV X19, X0

    ; RegOpenKeyExW(HKCU, "Software\Tetris", 0, KEY_READ, &hKey)
    MOVZ W0, #0x0001
    MOVK W0, #0x8000, LSL #16    ; HKEY_CURRENT_USER
    LDR X1, =reg_szRegPath
    MOV X2, #0
    MOVZ W3, #0x0019
    MOVK W3, #0x0002, LSL #16    ; KEY_READ = 0x20019
    ADD X4, SP, #LPN_HKEY

    BL RegOpenKeyExW
    CBNZ W0, lpn_not_found

    ; RegQueryValueExW(hKey, "PlayerName", NULL, &type, buffer, &size)
    MOV W8, #512
    STR W8, [SP, #LPN_SIZE]

    LDR X0, [SP, #LPN_HKEY]      ; arg 1: hKey
    LDR X1, =reg_szPlayerName    ; arg 2: lpValueName
    MOV X2, #0                   ; arg 3: lpReserved
    ADD X3, SP, #LPN_TYPE        ; arg 4: lpType
    ADD X4, SP, #LPN_BUF         ; arg 5: lpData
    ADD X5, SP, #LPN_SIZE        ; arg 6: lpcbData

    BL RegQueryValueExW
    STR W0, [SP, #LPN_RESULT]

    LDR X0, [SP, #LPN_HKEY]
    BL RegCloseKey

    LDR W0, [SP, #LPN_RESULT]
    CBNZ W0, lpn_not_found

    LDR W8, [SP, #LPN_TYPE]
    CMP W8, #1                   ; REG_SZ
    B.NE lpn_not_found

    ; Copy buffer to pGame->playerName
    ADD X8, X19, #GAME_STATE_playerName
    ADD X9, SP, #LPN_BUF
    MOV W10, #0

lpn_copy_loop
    LSL W11, W10, #1
    LDRH W12, [X9, W11, UXTW]
    STRH W12, [X8, W11, UXTW]
    CBZ W12, lpn_copy_done

    ADD W10, W10, #1
    CMP W10, #127
    B.LT lpn_copy_loop

lpn_copy_done
    LSL W11, W10, #1
    STRH WZR, [X8, W11, UXTW]

    MOV W0, #1
    B lpn_exit

lpn_not_found
    ADD X8, X19, #GAME_STATE_playerName
    STRH WZR, [X8]
    MOV W0, #0

lpn_exit
    LDP X19, X20, [SP, #LPN_SAVE]
    LDP X29, X30, [SP, #LPN_FP]
    ADD SP, SP, #LPN_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; SaveHighScore
; X0 = pGame
; Returns W0 = 1 on success, 0 on failure
; ---------------------------------------------------------------------------
SHS_FRAME  EQU 0x80
SHS_FP     EQU 0x70
SHS_SAVE   EQU 0x60
SHS_HKEY   EQU 0x40
SHS_SCORE  EQU 0x48
SHS_RESULT EQU 0x4C

SaveHighScore PROC
    SUB SP, SP, #SHS_FRAME
    STP X29, X30, [SP, #SHS_FP]
    ADD X29, SP, #SHS_FP
    STP X19, X20, [SP, #SHS_SAVE]

    MOV X19, X0

    ; RegCreateKeyExW
    MOVZ W0, #0x0001
    MOVK W0, #0x8000, LSL #16
    LDR X1, =reg_szRegPath
    MOV X2, #0
    MOV X3, #0
    MOV X4, #0
    MOVZ W5, #0x0006
    MOVK W5, #0x0002, LSL #16
    MOV X6, #0
    ADD X7, SP, #SHS_HKEY
    STR XZR, [SP, #0]

    BL RegCreateKeyExW
    CBNZ W0, shs_fail

    ; Save score DWORD
    LDR W8, [X19, #GAME_STATE_score]
    STR W8, [SP, #SHS_SCORE]

    LDR X0, [SP, #SHS_HKEY]
    LDR X1, =reg_szHighScore
    MOV X2, #0
    MOV X3, #4                   ; REG_DWORD
    ADD X4, SP, #SHS_SCORE
    MOV X5, #4

    BL RegSetValueExW
    STR W0, [SP, #SHS_RESULT]
    CBNZ W0, shs_close_fail

    ; Copy playerName to highScoreName, or use "Anonymous"
    ADD X8, X19, #GAME_STATE_playerName
    LDRH W9, [X8]
    CBNZ W9, shs_use_player

    ADD X8, X19, #GAME_STATE_highScoreName

    MOV W10, #65                 ; 'A'
    STRH W10, [X8, #0]
    MOV W10, #110                ; 'n'
    STRH W10, [X8, #2]
    MOV W10, #111                ; 'o'
    STRH W10, [X8, #4]
    MOV W10, #110                ; 'n'
    STRH W10, [X8, #6]
    MOV W10, #121                ; 'y'
    STRH W10, [X8, #8]
    MOV W10, #109                ; 'm'
    STRH W10, [X8, #10]
    MOV W10, #111                ; 'o'
    STRH W10, [X8, #12]
    MOV W10, #117                ; 'u'
    STRH W10, [X8, #14]
    MOV W10, #115                ; 's'
    STRH W10, [X8, #16]
    STRH WZR, [X8, #18]

    B shs_save_name

shs_use_player
    ADD X9, X19, #GAME_STATE_playerName
    ADD X8, X19, #GAME_STATE_highScoreName
    MOV W10, #0

shs_copy_name
    LSL W11, W10, #1
    LDRH W12, [X9, W11, UXTW]
    STRH W12, [X8, W11, UXTW]
    CBZ W12, shs_copy_done

    ADD W10, W10, #1
    CMP W10, #127
    B.LT shs_copy_name

shs_copy_done
    LSL W11, W10, #1
    STRH WZR, [X8, W11, UXTW]

shs_save_name
    ; Update in-memory high score
    LDR W8, [X19, #GAME_STATE_score]
    STR W8, [X19, #GAME_STATE_highScore]

    ; Save high score name
    ADD X0, X19, #GAME_STATE_highScoreName
    BL StrLenW
    ADD W0, W0, #1
    LSL W0, W0, #1
    MOV X20, X0                  ; byte size

    LDR X0, [SP, #SHS_HKEY]
    LDR X1, =reg_szHighScoreName
    MOV X2, #0
    MOV X3, #1                   ; REG_SZ
    ADD X4, X19, #GAME_STATE_highScoreName
    MOV X5, X20

    BL RegSetValueExW
    STR W0, [SP, #SHS_RESULT]

shs_close_fail
    LDR X0, [SP, #SHS_HKEY]
    BL RegCloseKey

    LDR W0, [SP, #SHS_RESULT]
    CBNZ W0, shs_fail

    MOV W0, #1
    B shs_exit

shs_fail
    MOV W0, #0

shs_exit
    LDP X19, X20, [SP, #SHS_SAVE]
    LDP X29, X30, [SP, #SHS_FP]
    ADD SP, SP, #SHS_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; LoadHighScore
; X0 = pGame
; Returns W0 = 1 if key opened, 0 if not found
; ---------------------------------------------------------------------------
LHS_FRAME EQU 0x180
LHS_FP    EQU 0x170
LHS_SAVE  EQU 0x160
LHS_BUF   EQU 0x40
LHS_HKEY  EQU 0x140
LHS_SIZE  EQU 0x148
LHS_TYPE  EQU 0x14C
LHS_SCORE EQU 0x150

LoadHighScore PROC
    SUB SP, SP, #LHS_FRAME
    STP X29, X30, [SP, #LHS_FP]
    ADD X29, SP, #LHS_FP
    STP X19, X20, [SP, #LHS_SAVE]

    MOV X19, X0

    ; RegOpenKeyExW
    MOVZ W0, #0x0001
    MOVK W0, #0x8000, LSL #16
    LDR X1, =reg_szRegPath
    MOV X2, #0
    MOVZ W3, #0x0019
    MOVK W3, #0x0002, LSL #16
    ADD X4, SP, #LHS_HKEY

    BL RegOpenKeyExW
    CBNZ W0, lhs_fail_default

    ; Read high score DWORD
    MOV W8, #4
    STR W8, [SP, #LHS_SIZE]

    LDR X0, [SP, #LHS_HKEY]
    LDR X1, =reg_szHighScore
    MOV X2, #0
    ADD X3, SP, #LHS_TYPE
    ADD X4, SP, #LHS_SCORE
    ADD X5, SP, #LHS_SIZE

    BL RegQueryValueExW
    CBNZ W0, lhs_read_name

    LDR W8, [SP, #LHS_TYPE]
    CMP W8, #4                   ; REG_DWORD
    B.NE lhs_read_name

    LDR W8, [SP, #LHS_SCORE]
    STR W8, [X19, #GAME_STATE_highScore]

lhs_read_name
    ; Read high score name
    MOV W8, #512
    STR W8, [SP, #LHS_SIZE]

    LDR X0, [SP, #LHS_HKEY]
    LDR X1, =reg_szHighScoreName
    MOV X2, #0
    ADD X3, SP, #LHS_TYPE
    ADD X4, SP, #LHS_BUF
    ADD X5, SP, #LHS_SIZE

    BL RegQueryValueExW
    CBNZ W0, lhs_cleanup

    LDR W8, [SP, #LHS_TYPE]
    CMP W8, #1                   ; REG_SZ
    B.NE lhs_cleanup

    ADD X8, X19, #GAME_STATE_highScoreName
    ADD X9, SP, #LHS_BUF
    MOV W10, #0

lhs_copy_loop
    LSL W11, W10, #1
    LDRH W12, [X9, W11, UXTW]
    STRH W12, [X8, W11, UXTW]
    CBZ W12, lhs_cleanup

    ADD W10, W10, #1
    CMP W10, #127
    B.LT lhs_copy_loop

    LSL W11, W10, #1
    STRH WZR, [X8, W11, UXTW]

lhs_cleanup
    LDR X0, [SP, #LHS_HKEY]
    BL RegCloseKey

    MOV W0, #1
    B lhs_exit

lhs_fail_default
    STR WZR, [X19, #GAME_STATE_highScore]
    ADD X8, X19, #GAME_STATE_highScoreName
    STRH WZR, [X8]
    MOV W0, #0

lhs_exit
    LDP X19, X20, [SP, #LHS_SAVE]
    LDP X29, X30, [SP, #LHS_FP]
    ADD SP, SP, #LHS_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; ClearRegistry
; Deletes HKCU\Software\Tetris
; Returns W0 = 1 on success, 0 on failure
; ---------------------------------------------------------------------------
ClearRegistry PROC
    STP X29, X30, [SP, #-32]!
    MOV X29, SP

    MOVZ W0, #0x0001
    MOVK W0, #0x8000, LSL #16    ; HKEY_CURRENT_USER
    LDR X1, =reg_szRegPath
    BL RegDeleteKeyW

    CBZ W0, cr_ok
    CMP W0, #2                   ; ERROR_FILE_NOT_FOUND
    B.EQ cr_ok

    MOV W0, #0
    B cr_exit

cr_ok
    MOV W0, #1

cr_exit
    LDP X29, X30, [SP], #32
    RET
    ENDP

    END