import sdl2_nim/sdl
import nico
import nico/vec
import nimigolf/consts
import nimigolf/base
import nimigolf/trajectory
import nimigolf/ballobj
import nimigolf/level
import nimigolf/converters


# Global vars

var
  finished: bool
  curPlayer: int
  gameObjects = newSeq[Obj]()
  balls = newSeq[Ball]()
  tl = newTrajectoryLine()

proc currentBall(): Ball {.inline.} =
  result = balls[curPlayer]

proc loadGfx() =
  loadFont(0, "fonts/onix.png")
  setPalette(loadPaletteFromGPL("palette/tiles.gpl"))
  loadSpritesheet(1, "tiles/Tilesheet-land-v5.png", TS, TS)

proc resetObjects() =
  for b in balls:
    b.reset()

proc createObjects() =
  var b = newBall()
  gameObjects.add(tl)
  balls.add(b)
  gameObjects.add(b)

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

proc debugDraw() =
  let b = currentBall()
  setColor(0)
  print("Debug:", 32, 32)
  print("Ball X:" & $b.pos.x.ceil & " Y:" & $b.pos.y.ceil, 32, 48)
  print("Tile type: " & $mget(b.centerTile[0], b.centerTile[1]), 32,64)
  print("Tile position X:" & $b.tilePos.x & " Y:" & $b.tilePos.y, 32,80)

proc gameInit() =
  loadGfx()
  loadMaps()
  resetLevel()
  createObjects()

proc gameUpdate(dt: float32) =
  if finished:
    return
  if btnp(pcBack):
    finished = true
  if mousebtn(2):
    let m = mouse()
    debug "MOUSE: " & m.repr
    debug "HOLE: " & holePos.repr
    currentBall().reset
    currentBall().pos.x = m[0] - TS div 2
    currentBall().pos.y = m[1] - TS div 2
  if mousebtn(0) and not currentBall().isMoving:
    let m = mouse()
    if dist(currentBall().center, m) <= 5:
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
    ball.update()
  if allBallsInHole():
    curMap.inc
    if curMap >= loadedLevels:
      finished = true
      return
    debug "Loading level: " & $curMap
    resetLevel()
    resetObjects()

proc gameDraw() =
  # delay(10)
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

  debugDraw()

nico.init(orgName, appName)
nico.createWindow(appName, SCREENW, SCREENH, 1, false)

fixedSize(true)
integerScale(true)

nico.run(gameInit, gameUpdate, gameDraw)
