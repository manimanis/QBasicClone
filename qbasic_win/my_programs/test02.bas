gamespeed$ = "1"
speed = VAL(gamespeed$)
speed = (200 - speed) * 2 + 1
startTime# = TIMER
FOR i# = 1 TO 1000: NEXT i#
stopTime# = TIMER
speed = speed * .5 / (stopTime# - startTime#)
PRINT speed
PRINT startTime#
PRINT stopTime#