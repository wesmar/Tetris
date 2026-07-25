; data.inc
; ARM64 (armasm64, Windows) - structure offsets
; Natural alignment for Windows ARM64.

; ---------------------------------------------------------------------------
; POINT_STRUCT
; ---------------------------------------------------------------------------
POINT_STRUCT_SIZE       EQU 8
POINT_STRUCT_x          EQU 0
POINT_STRUCT_y          EQU 4

; ---------------------------------------------------------------------------
; PARTICLE
; 20 bytes: keeps 32-bit vx/vy.
; ---------------------------------------------------------------------------
PARTICLE_STRUCT_SIZE    EQU 20
PARTICLE_active         EQU 0
PARTICLE_color          EQU 1
PARTICLE_life           EQU 2
PARTICLE_padding        EQU 3
PARTICLE_x              EQU 4
PARTICLE_y              EQU 8
PARTICLE_vx             EQU 12
PARTICLE_vy             EQU 16

; ---------------------------------------------------------------------------
; PIECE
; ---------------------------------------------------------------------------
PIECE_SIZE              EQU 48
PIECE_shapeType         EQU 0
PIECE_color             EQU 1
PIECE_padding           EQU 2
PIECE_x                 EQU 4
PIECE_y                 EQU 8
PIECE_yFloat            EQU 12
PIECE_blocks            EQU 16

PIECE_block0_x          EQU 16
PIECE_block0_y          EQU 20
PIECE_block1_x          EQU 24
PIECE_block1_y          EQU 28
PIECE_block2_x          EQU 32
PIECE_block2_y          EQU 36
PIECE_block3_x          EQU 40
PIECE_block3_y          EQU 44

; ---------------------------------------------------------------------------
; GAME_STATE
; ---------------------------------------------------------------------------
GAME_STATE_boardWidth           EQU 0
GAME_STATE_boardHeight          EQU 4
GAME_STATE_board                EQU 8

GAME_STATE_currentPiece         EQU GAME_STATE_board + 400
GAME_STATE_nextPiece            EQU GAME_STATE_currentPiece + PIECE_SIZE

GAME_STATE_score                EQU GAME_STATE_nextPiece + PIECE_SIZE
GAME_STATE_lines                EQU GAME_STATE_score + 4
GAME_STATE_level                EQU GAME_STATE_lines + 4

GAME_STATE_gameOver             EQU GAME_STATE_level + 4
GAME_STATE_paused               EQU GAME_STATE_gameOver + 1
GAME_STATE_showGhost            EQU GAME_STATE_paused + 1
GAME_STATE_padding              EQU GAME_STATE_showGhost + 1

GAME_STATE_rngSeed              EQU GAME_STATE_padding + 1
GAME_STATE_playerName           EQU GAME_STATE_rngSeed + 4
GAME_STATE_highScore            EQU GAME_STATE_playerName + 256
GAME_STATE_highScoreName        EQU GAME_STATE_highScore + 4
GAME_STATE_yFloat               EQU GAME_STATE_highScoreName + 256

GAME_STATE_clearActive          EQU GAME_STATE_yFloat + 4
GAME_STATE_clearCount           EQU GAME_STATE_clearActive + 1
GAME_STATE_clearPad             EQU GAME_STATE_clearCount + 1
GAME_STATE_clearMask            EQU GAME_STATE_clearPad + 2
GAME_STATE_clearTimer           EQU GAME_STATE_clearMask + 4

GAME_STATE_particles            EQU GAME_STATE_clearTimer + 4
GAME_STATE_particleCount        EQU GAME_STATE_particles + (64 * PARTICLE_STRUCT_SIZE)

GAME_STATE_SIZE                 EQU GAME_STATE_particleCount + 4

; Convenience offsets: currentPiece
GAME_STATE_currentPiece_shapeType   EQU GAME_STATE_currentPiece + PIECE_shapeType
GAME_STATE_currentPiece_color       EQU GAME_STATE_currentPiece + PIECE_color
GAME_STATE_currentPiece_x           EQU GAME_STATE_currentPiece + PIECE_x
GAME_STATE_currentPiece_y           EQU GAME_STATE_currentPiece + PIECE_y
GAME_STATE_currentPiece_yFloat      EQU GAME_STATE_currentPiece + PIECE_yFloat
GAME_STATE_currentPiece_blocks      EQU GAME_STATE_currentPiece + PIECE_blocks

; Convenience offsets: nextPiece
GAME_STATE_nextPiece_shapeType      EQU GAME_STATE_nextPiece + PIECE_shapeType
GAME_STATE_nextPiece_color          EQU GAME_STATE_nextPiece + PIECE_color
GAME_STATE_nextPiece_x              EQU GAME_STATE_nextPiece + PIECE_x
GAME_STATE_nextPiece_y              EQU GAME_STATE_nextPiece + PIECE_y
GAME_STATE_nextPiece_yFloat         EQU GAME_STATE_nextPiece + PIECE_yFloat
GAME_STATE_nextPiece_blocks         EQU GAME_STATE_nextPiece + PIECE_blocks

; ---------------------------------------------------------------------------
; RENDERER_STATE
; ---------------------------------------------------------------------------
RENDERER_STATE_hwnd           EQU 0
RENDERER_STATE_hdcMem         EQU 8
RENDERER_STATE_hbmMem         EQU 16
RENDERER_STATE_hbmOld         EQU 24
RENDERER_STATE_wWidth         EQU 32
RENDERER_STATE_wHeight        EQU 36
RENDERER_STATE_hFontNormal    EQU 40
RENDERER_STATE_hFontSmall     EQU 48
RENDERER_STATE_hFontPause     EQU 56
RENDERER_STATE_hFontGameOver  EQU 64
RENDERER_STATE_colorBrushes   EQU 72
RENDERER_STATE_pausePulse     EQU RENDERER_STATE_colorBrushes + 64

RENDERER_STATE_SIZE           EQU 144

    END
