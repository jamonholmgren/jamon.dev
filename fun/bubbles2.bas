DECLARE SUB FishDraw (x%, y%, m%)
DECLARE SUB BubbleDraw (x%, y%, D%, b%)
DECLARE SUB GameLoop ()
DECLARE SUB Initialize ()
DefInt A-Z

Type BubType
    x As Integer
    y As Integer
    s As Integer
    op As Integer
End Type
Type FishType
    x As Integer
    y As Integer
    mx As Integer
    my As Integer
    op As Integer
End Type

Const FPS = 60

' Shared variables
Dim Shared bx As Integer, by As Integer
Dim Shared mx As Integer, my As Integer
Dim Shared bd As Integer, bb As Integer
Dim Shared Tide As Integer, TideCtr As Integer
Dim Shared bubmeter As Integer
Dim Shared Points As Integer
Dim Shared bub(1 To 10) As BubType
Dim Shared fish(1 To 5) As FishType
Dim Shared ActiveFish As Integer

' Constants
Const speed = 5
Const MaxBubs = 10
Const bubspeed = 1
Const fartlength = 2
Const freefall = 5
Const Fishes = 5
Const KillZone = 5
Const TideSpd = 1000

' Main program
Call Initialize

' Set up the timer for game loop
Dim gameTimer As Integer
gameTimer = _FreeTimer
On Timer(gameTimer, 1 / FPS) GameLoop
Timer(gameTimer) On

' Main loop
Do
    _Limit FPS ' Limit the frame rate
    K$ = InKey$
    If K$ = Chr$(27) Then Exit Do ' Exit if ESC is pressed

    ' Handle input
    Select Case UCase$(K$)
        Case "A"
            mx = mx - 1
            If mx < -speed Then mx = -speed
            bd = -1
        Case "D"
            mx = mx + 1
            If mx > speed Then mx = speed
            bd = 1
        Case "S"
            mx = 0
        Case "W"
            If by > Tide Then my = -5
        Case "B", " "
            If bubmeter > 20 Then
                For i = 1 To MaxBubs
                    If bub(i).op = 0 Then
                        For fart = 1 To fartlength
                            Sound Int(Rnd * 50) + 50, .1
                        Next fart
                        bubmeter = bubmeter - 25
                        bub(i).op = 1
                        bub(i).x = bx
                        bub(i).y = by
                        bub(i).s = 3
                        Exit For
                    End If
                Next i
            End If
    End Select
Loop

' Clean up
Timer(gameTimer) Off
Timer(gameTimer) Free
End

' Initialize game state
Sub Initialize
    Screen 9, , 0, 1
    Randomize Timer

    bx = 300
    by = 250
    mx = 0
    my = 0
    bd = 1
    bb = 0
    Tide = 40
    TideCtr = 0
    bubmeter = 100
    Points = 0
    ActiveFish = 0
End Sub

' Game loop subroutine
Sub GameLoop
    Cls

    ' Update game state
    If mx <> 0 Then
        If bb = 0 Then bb = 1 Else bb = 0
    Else
        bb = 0
    End If

    bx = bx + mx
    If bx < 10 Then bx = 10: mx = 0
    If bx > 630 Then bx = 630: mx = 0
    my = my + 1
    If my > freefall Then my = freefall
    by = by + my
    If by > 250 Then
        by = 250
        my = 0
    ElseIf by < Tide Then
        my = 0
    End If

    TideCtr = TideCtr + 1
    If TideCtr > TideSpd Then
        TideCtr = 0
        Tide = Tide + 1
        If Tide > 245 Then
            Screen 9, , 0, 0
            Cls
            Print "Congratulations, you scored "; Points; " points!"
            Play "c a f c a d g c a f e a g f c"
            Print "The end."
            System
        End If
    End If

    If bd = -1 And mx > 0 Then
        If Int(Rnd * 3) = 0 Then mx = mx - 1
        Sound 100 + Int(Rnd * 150), .1
    ElseIf bd = 1 And mx < 0 Then
        If Int(Rnd * 3) = 0 Then mx = mx + 1
        Sound 100 + Int(Rnd * 150), .1
    End If

    ' Draw game elements
    Line (0, 0)-(650, Tide), 9, BF 'sky
    Line (0, Tide + 1)-(650, 250), 1, BF 'water
    Line (0, 251)-(650, 320), 6, BF 'ground

    bubmeter = bubmeter + bubspeed
    If bubmeter > 100 Then bubmeter = 100
    Line (30, 300)-Step(bubmeter, 10), 12, BF

    ActiveFish = 0
    For i = 1 To Fishes
        If fish(i).op <> 0 Then
            Call FishDraw(fish(i).x, fish(i).y, fish(i).mx)
            fish(i).x = fish(i).x + fish(i).mx
            fish(i).y = fish(i).y + fish(i).my
            If fish(i).op = 3 Then
                If fish(i).y > 245 Then
                    fish(i).op = 0
                    Sound 50, 1
                    Points = Points + 10
                End If
            Else
                If fish(i).y < Tide Then fish(i).my = 3
                If fish(i).y > 240 Then fish(i).my = -3
                If Int(Rnd * 20) = 1 Then
                    fish(i).my = Int(Rnd * 3) - 1
                    If fish(i).my > 3 Then fish(i).my = 3
                    If fish(i).my < -3 Then fish(i).my = -3
                End If
                ' Remove fish if they go off-screen
                If fish(i).x < -30 Or fish(i).x > 670 Then
                    fish(i).op = 0
                Else
                    ActiveFish = ActiveFish + 1
                End If
            End If
        End If
    Next i

    Call BubbleDraw(bx, by, bd, bb)

    Locate 22, 60
    Print "Points:"; Points

    For i = 1 To MaxBubs
        If bub(i).op <> 0 Then
            bub(i).y = bub(i).y - Int(Rnd * 4)
            bub(i).x = bub(i).x + Int(Rnd * 3) - 1
            If bub(i).y < Tide Then
                bub(i).op = 0
                Sound 500, .3
            End If
            s = Int(Rnd * 3) + 3
            Circle (bub(i).x, bub(i).y), s, 15
            For f = 1 To Fishes
                If bub(i).x - KillZone < fish(f).x And bub(i).x + KillZone > fish(f).x Then
                    If bub(i).y - KillZone < fish(f).y And bub(i).y + KillZone > fish(f).y Then
                        fish(f).my = 3
                        fish(f).mx = 0
                        fish(f).op = 3
                    End If
                End If
            Next f
        End If
    Next i

    PCopy 0, 1

    If Int(Rnd * 15) = 1 Or ActiveFish = 0 Then
        For i = 1 To Fishes
            If fish(i).op = 0 Then
                fish(i).op = Not 0
                If Int(Rnd * 2) = 0 Then
                    fish(i).x = -20
                    fish(i).mx = Int(Rnd * 3) + 1
                Else
                    fish(i).x = 660
                    fish(i).mx = -1 * (Int(Rnd * 3) + 1)
                End If
                fish(i).my = 0
                fish(i).y = Int(Rnd * 100) + 50
                ActiveFish = ActiveFish + 1
                Exit For
            End If
        Next i
    End If
End Sub

Sub BubbleDraw (x, y, D, b)
    Line (x - 4 + b, y)-Step(-2, -2), 2, BF
    Line (x + 4 - b, y)-Step(2, -2), 2, BF
    If D = 1 Then
        Circle (x + 7, y - 7), 3, 11
        Paint Step(0, 0), 11, 11
        Line Step(1, -5)-Step(-1, 5), 6
        PSet Step(1, -1), 0
    Else
        Circle (x - 7, y - 7), 3, 10
        Paint Step(0, 0), 10, 10
        Line Step(-1, -5)-Step(1, 5), 6
        PSet Step(-1, -1), 0
    End If
    Circle (x, y - 5 - b), 5, 10
    Paint Step(0, 0), 10, 10
End Sub

Sub FishDraw (x, y, m)
    Line (x + (Sgn(m) * -11), y - 3)-Step(0, 6), 3
    Line -Step(Sgn(m) * 5, -3), 3
    Line -Step(Sgn(m) * -5, -3), 3
    Circle (x, y), 6, 3, , , .5
End Sub

