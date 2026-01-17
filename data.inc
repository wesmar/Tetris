POINT_STRUCT STRUCT
    x DWORD ?
    y DWORD ?
POINT_STRUCT ENDS

PIECE STRUCT
    shapeType BYTE ?
    color BYTE ?
    padding WORD ?
    x DWORD ?
    y DWORD ?
    yFloat DWORD ?
    blocks POINT_STRUCT 4 DUP(<>)
PIECE ENDS

GAME_STATE STRUCT
    boardWidth DWORD ?
    boardHeight DWORD ?
    board BYTE 400 DUP(?)
    currentPiece PIECE <>
    nextPiece PIECE <>
    score DWORD ?
    lines DWORD ?
    level DWORD ?
    gameOver BYTE ?
    paused BYTE ?
    padding WORD ?
    rngSeed DWORD ?
    playerName WORD 128 DUP(?)
    highScore DWORD ?
    highScoreName WORD 128 DUP(?)
    yFloat DWORD ?
GAME_STATE ENDS

RENDERER_STATE STRUCT
    hwnd DWORD ?
    hdcMem DWORD ?
    hbmMem DWORD ?
    hbmOld DWORD ?
    wWidth DWORD ?
    wHeight DWORD ?
    hFontNormal DWORD ?
    hFontSmall DWORD ?
    hFontPause DWORD ?
    hFontGameOver DWORD ?
    colorBrushes DWORD 8 DUP(?)
RENDERER_STATE ENDS
