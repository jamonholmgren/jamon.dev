' This is the original BUBBLES.BAS game
' by Jamon Holmgren around 2001-ish
' Running this on modern qb64 makes it wayy too fast
' so check out bubbles2.bas in this same directory
' for a more modern version that runs better.
' You can also download a binary from jamon.dev

DECLARE SUB FishDraw (x%, y%, m%)
DECLARE SUB BubbleDraw (x%, y%, D%, b%)
DEFINT A-Z

TYPE BubType
    x       AS INTEGER
    y       AS INTEGER
    s       AS INTEGER
    op      AS INTEGER
END TYPE
TYPE FishType
    x       AS INTEGER
    y       AS INTEGER
    mx      AS INTEGER
    my      AS INTEGER
    op      AS INTEGER
END TYPE

SCREEN 9, , 0, 1

CONST speed = 5
CONST MaxBubs = 10
CONST bubspeed = 1
CONST fartlength = 2
CONST freefall = 5
CONST Fishes = 5
CONST KillZone = 5

Points = 0

DIM SHARED bub(1 TO MaxBubs) AS BubType
DIM SHARED fish(1 TO Fishes) AS FishType

bx = 300
by = 250

mx = 0
my = 0

bd = 1
bb = 0

Tide = 40
TideCtr = 0
CONST TideSpd = 10
               
bubmeter = 100

DO
    CLS
    IF mx <> 0 THEN
        IF bb = 0 THEN bb = 1:  ELSE bb = 0
    ELSE
        bb = 0
    END IF
    bx = bx + mx
    IF bx < 10 THEN bx = 10: mx = 0
    IF bx > 630 THEN bx = 630: mx = 0
    my = my + 1
    IF my > freefall THEN
        my = freefall
    END IF
    by = by + my
    IF by > 250 THEN
        by = 250
        my = 0
    ELSEIF by < Tide THEN
        my = 0
    END IF

    TideCtr = TideCtr + 1
    IF TideCtr > TideSpd THEN
        TideCtr = 0
        Tide = Tide + 1
        IF Tide > 245 THEN
            SCREEN 9, , 0, 0
            CLS
            PRINT "Congratulations, you scored "; Points; " points!"
            PLAY "c a f c a d g c a f e a g f c"
            PRINT "The end."
            SYSTEM
        END IF
    END IF
   
    IF bd = -1 AND mx > 0 THEN
        IF INT(RND * 3) = 0 THEN
            mx = mx - 1
        END IF
        SOUND 100 + INT(RND * 150), .1
    ELSEIF bd = 1 AND mx < 0 THEN
        IF INT(RND * 3) = 0 THEN
            mx = mx + 1
        END IF
        SOUND 100 + INT(RND * 150), .1
    END IF
   
    LINE (0, 0)-(650, Tide), 9, BF   'sky
    LINE (0, Tide + 1)-(650, 250), 1, BF'water
    LINE (0, 251)-(650, 320), 6, BF 'ground
      
    bubmeter = bubmeter + bubspeed
    IF bubmeter > 100 THEN bubmeter = 100
    LINE (30, 300)-STEP(bubmeter, 10), 12, BF

    FOR i = 1 TO Fishes
        IF fish(i).op <> 0 THEN
            FishDraw fish(i).x, fish(i).y, fish(i).mx
            fish(i).x = fish(i).x + fish(i).mx
            fish(i).y = fish(i).y + fish(i).my
            IF fish(i).op = 3 THEN
                IF fish(i).y > 245 THEN
                    fish(i).op = 0
                    SOUND 50, 1
                    Points = Points + 10
                END IF
            ELSE
                IF fish(i).y < Tide THEN fish(i).my = 3
                IF fish(i).y > 240 THEN fish(i).my = -3
                IF INT(RND * 20) = 1 THEN
                    fish(i).my = INT(RND * 3) - 1
                    IF fish(i).my > 3 THEN fish(i).my = 3
                    IF fish(i).my < -3 THEN fish(i).my = -3
                END IF
            END IF
        END IF
    NEXT i
   
    BubbleDraw bx, by, bd, bb

    LOCATE 22, 60
    PRINT "Points:"; Points

    FOR i = 1 TO MaxBubs
        IF bub(i).op <> 0 THEN
            bub(i).y = bub(i).y - INT(RND * 4)
            bub(i).x = bub(i).x + INT(RND * 3) - 1
            IF bub(i).y < Tide THEN
                bub(i).op = 0
                SOUND 500, .3
            END IF
            s = INT(RND * 3) + 3
            CIRCLE (bub(i).x, bub(i).y), s, 15
            FOR f = 1 TO Fishes
                IF bub(i).x - KillZone < fish(f).x AND bub(i).x + KillZone > fish(f).x THEN
                    IF bub(i).y - KillZone < fish(f).y AND bub(i).y + KillZone > fish(f).y THEN
                        fish(f).my = 3
                        fish(f).mx = 0
                        fish(f).op = 3
                    END IF
                END IF
            NEXT f
        END IF
    NEXT i
   
    PCOPY 0, 1
    IF INT(RND * 25) = 1 THEN
        FOR i = 1 TO Fishes
            IF fish(i).op = 0 THEN
                fish(i).op = NOT 0
                IF INT(RND * 2) = 0 THEN
                    fish(i).x = -20
                    fish(i).mx = INT(RND * 3) + 1
                ELSE
                    fish(i).x = 660
                    fish(i).mx = -1 * (INT(RND * 3) + 1)
                END IF
                
                fish(i).my = 0
                fish(i).y = INT(RND * 100) + 50
                EXIT FOR
            END IF
        NEXT i
    END IF
    a$ = INKEY$
    SELECT CASE UCASE$(a$)
        CASE CHR$(27)
            SYSTEM
        CASE "A"
            mx = mx - 1
            IF mx < -speed THEN mx = -speed
            bd = -1
        CASE "D"
            mx = mx + 1
            IF mx > speed THEN mx = speed
         
            bd = 1
        CASE "S"
            mx = 0
        CASE "W"
            IF by > Tide THEN my = -5
        CASE "B", " "
            IF bubmeter > 20 THEN
                FOR i = 1 TO MaxBubs
                    IF bub(i).op = 0 THEN
                        FOR fart = 1 TO fartlength
                            SOUND INT(RND * 50) + 50, .1
                        NEXT fart
                        bubmeter = bubmeter - 25
                        bub(i).op = 1
                        bub(i).x = bx
                        bub(i).y = by
                        bub(i).s = 3
                        EXIT FOR
                    END IF
                NEXT i
            END IF
    END SELECT
LOOP



SUB BubbleDraw (x, y, D, b)
    LINE (x - 4 + b, y)-STEP(-2, -2), 2, BF
    LINE (x + 4 - b, y)-STEP(2, -2), 2, BF
    IF D = 1 THEN
        CIRCLE (x + 7, y - 7), 3, 11
        PAINT STEP(0, 0), 11, 11
        LINE STEP(1, -5)-STEP(-1, 5), 6
        PSET STEP(1, -1), 0
    ELSE
        CIRCLE (x - 7, y - 7), 3, 10
        PAINT STEP(0, 0), 10, 10
        LINE STEP(-1, -5)-STEP(1, 5), 6
        PSET STEP(-1, -1), 0
    END IF
    CIRCLE (x, y - 5 - b), 5, 10
    PAINT STEP(0, 0), 10, 10
END SUB

SUB FishDraw (x, y, m)
    LINE (x + (SGN(m) * -11), y - 3)-STEP(0, 6), 3
    LINE -STEP(SGN(m) * 5, -3), 3
    LINE -STEP(SGN(m) * -5, -3), 3
    CIRCLE (x, y), 6, 3, , , .5
END SUB
