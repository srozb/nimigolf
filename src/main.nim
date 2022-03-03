import sequtils
import nico
import nico/vec
import nimigolf/consts
import nimigolf/base
import nimigolf/trajectory
import nimigolf/ballobj
import nimigolf/level


# Global vars

var
  finished: bool
  curPlayer: int
  gameObjects = newSeq[Obj]()
  balls = newSeq[Ball]()
  tl = newTrajectoryLine()

## Ball
proc currentBall(): Ball =  # TODO: cleanup
  result = balls[curPlayer]

proc loadGfx() =
  loadFont(0, "fonts/onix.png")
  setPalette(loadPaletteFromGPL("palette/tiles.gpl"))
  loadSpritesheet(1, "tiles/Tilesheet-land-v5.png", TS, TS)

proc resetObjects() =
  for b in balls:
    b.reset()

proc createObjects() =
  var b = newBall(startPos.x, startPos.y)
  gameObjects.add(tl)
  balls.add(b)
  gameObjects.add(b)

proc gameInit() =
  loadGfx()
  loadMaps()
  resetLevel()
  createObjects()

proc allBallsInHole(): bool =
  result = true
  for b in balls:
    if b.visible:
      return false

proc gameOver() =
  # Shot the game over screen
  setColor(254)
  printc("Game Over", screenWidth div 2, screenHeight div 2)
  var scoresOffset = screenHeight div 2
  for b in balls:
    scoresOffset.inc 32
    printc(b.getGameScoreCap(), screenWidth div 2, scoresOffset)

proc gameUpdate(dt: float32) =
  if btnp(pcBack):
    finished = true
  if mousebtn(2):
    let m = mouse()
    debug "MOUSE: " & m.repr
    debug "HOLE: " & holePos.repr
  if mousebtn(0) and not currentBall().isMoving:
    let m = mouse()
    if objDistance(currentBall(), m) < 5:
      tl.visible = true
      hideMouse()
      tl.pos = center(currentBall())
    tl.frc.x = m[0]  # TODO: Scale
    tl.frc.y = m[1]
  else:
    if tl.visible == true:
      tl.visible = false
      currentBall().shoot(tl)  # TODO: min force needed to shot
      showMouse()
  for ball in balls:
    ball.updatePosition()
    if ball.inHole:
      ball.visible = false
  if allBallsInHole():
    curMap.inc
    if curMap >= loadedLevels:
      finished = true
      return
    debug "Loading level: " & $curMap
    resetLevel()
    resetObjects()

proc gameDraw() =
  cls()

  if finished:
    gameOver()
    if btnp(pcBack):
      shutdown()
    return

  setSpritesheet(1)
  mapdraw(0, 0, MAPW, MAPH, 0, 0)

  for ob in gameObjects:
    ob.draw()

nico.init(orgName, appName)
nico.createWindow(appName, SCREENW, SCREENH, 1, false)
nico.run(gameInit, gameUpdate, gameDraw)

integerScale(true)
