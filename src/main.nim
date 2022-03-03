import os
import nico
import nico/vec
import strutils
import math
import nimigolf/consts
import nimigolf/base
import nimigolf/trajectory
import nimigolf/converters

type
  bncType = enum
    bHor, bVer, bDiagSl, bDiagBSl

  Ball = ref object of Obj
    id, shots: int
    justBounced: bool

# Global vars

var
  finished: bool
  curMap, curPlayer, players, loadedLevels: int
  gameObjects = newSeq[Obj]()
  balls = newSeq[Ball]()
  startPos, holePos: Vec2i
  tl = newTrajectoryLine()

## Ball

proc newBall(x, y: int): Ball =
  result = new Ball
  result.pos.x = x - TS div 2
  result.pos.y = y - TS div 2
  result.hitbox.x = TS div 2
  result.hitbox.w = 6
  result.hitbox.y = TS div 2
  result.hitbox.h = 6
  result.id = players
  result.visible = true
  players.inc

method draw(self: Ball) =
  if self.visible:
    spr(73+self.id, self.pos.x, self.pos.y)

method reset(self: Ball) =
  # Resets the ball position
  self.visible = true
  self.pos.x = startPos[0] - TS div 2
  self.pos.y = startPos[1] - TS div 2
  self.vel.x = 0
  self.vel.y = 0

proc getPlayer(self: Ball): string =
  return "Player " & $(self.id + 1)

proc getGameScoreCap(self: Ball): string =
  return self.getPlayer() & ": " & $self.shots

proc stop(self: Ball) =
  self.vel.x = 0
  self.vel.y = 0

proc shouldScore(self: Ball): bool {.inline.} =
  return (abs(self.center[0] - holePos.x) + abs(self.center[1] - holePos.y)) < 3

method center(self: Ball): (int, int) {.inline.} =
  result = (self.pos.x.toInt + self.hitbox.x, self.pos.y.toInt + self.hitbox.y)

method center(self: Ball): Vec2 {.inline.} =
  result.x = self.pos.x.toInt + self.hitbox.x
  result.y = self.pos.y.toInt + self.hitbox.y

method centerTile(self: Ball): (Pint, Pint) {.inline.} =
  let coords = self.center()
  result = pixelToMap(coords[0], coords[1])

method tilePos(self: Ball): (Pint, Pint) {.inline.} =
  #Returns the position of the ball on current tile
  let coords = self.center()
  result = (coords[0] mod TS, coords[1] mod TS)

proc bounce(self: Ball, bounces: var seq[bncType]) =
  while bounces.len > 0:
    self.justBounced = true
    case bounces.pop
    of bHor:
      self.vel.y *= -BOUNCY
    of bVer:
      self.vel.x *= -BOUNCY
    of bDiagSl:
      (self.vel.x, self.vel.y) = (self.vel.y * -BOUNCY, self.vel.x * -BOUNCY) 
    of bDiagBSl:
      (self.vel.x, self.vel.y) = (self.vel.y * BOUNCY, self.vel.x * BOUNCY)

proc bounceIfCollision(self: Ball): bool =
  if self.justBounced: # to be sure, not bounced twice
    return false
  let
    ballTile = self.centerTile()
    curTile = mget(ballTile[0], ballTile[1])
    ballTilePos = self.tilePos()
  var bounces = newSeq[bncType]()
  if curTile in HBOUNDS:
    bounces.add(bHor)
  elif curTile in VBOUNDS:
    bounces.add(bVer)
  elif curTile in DBOUNDS:
    bounces.add(bDiagSl)
  elif curTile in BDBOUNDS:
    bounces.add(bDiagBSl)
  elif curTile in HDBOUNDS and ballTilePos[0] + ballTilePos[1] - TS < 3:
    bounces.add(bDiagSl)
  elif curTile in HBDBOUNDS and abs(ballTilePos[0] - ballTilePos[1]) < 3:
    bounces.add(bDiagBSl)
  self.bounce(bounces)

proc turnNearHole(self: Ball) =
  let holeDist = self.objDistance(holePos)
  if holeDist > 25:
    return
  var slopeForce: Vec2f
  slopeForce.x = (holePos.x - self.center[0]) / holeDist^2
  slopeForce.y = (holePos.y - self.center[1]) / holeDist^2
  self.vel += slopeForce

proc updatePosition(self: Ball) =
  self.pos.x += self.vel.x
  self.pos.y += self.vel.y
  self.vel.x *= DECCEL
  self.vel.y *= DECCEL
  if abs(self.vel.x) + abs(self.vel.y) < STOP_TH:
    self.stop()
  self.justBounced = self.bounceIfCollision()
  self.turnNearHole

proc isMoving(self: Ball): bool =
  return self.vel.x != 0 or self.vel.y != 0

proc shoot(self: Ball) =
  self.vel = tl.asVel(0.2)
  self.shots.inc

proc currentBall(): Ball =
  result = balls[curPlayer]

proc setObjTile(self: var Vec2i, tx, ty: Pint) =
  # let pos = mapToPixel(tx, ty)  # TODO
  self[0] = (tx * TS) + TS/2
  self[1] = (ty * TS) + TS/2

proc loadGfx() =
  loadFont(0, "fonts/onix.png")
  setPalette(loadPaletteFromGPL("palette/tiles.gpl"))
  loadSpritesheet(1, "tiles/Tilesheet-land-v5.png", TS, TS)

proc loadMaps() =
  for mFile in walkPattern("assets/levels/*.json"):
    newMap(curMap, MAPW, MAPH, TS, TS)
    loadMap(curMap, mFile.split("/", 1)[1])
    curMap.inc
    loadedLevels.inc
  curMap = 0

proc resetLevel() =
  setMap(curMap)

  for y in 0..<MAPH:
    for x in 0..<MAPW:
      case mget(x, y)
      of 84:
        startPos.setObjTile(x, y)
      of 94:
        holePos.setObjTile(x, y)
      else:
        discard

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
      tl.pos.x = center(currentBall())[0]
      tl.pos.y = center(currentBall())[1]
      # tl.x1 = center(currentBall())[0]
      # tl.y1 = center(currentBall())[1]
    tl.frc.x = m[0]
    tl.frc.y = m[1]
    # tl.x2 = m[0]  # TODO: scale
    # tl.y2 = m[1]
  else:
    if tl.visible == true:
      tl.visible = false
      currentBall().shoot
      showMouse()
  for ball in balls:
    ball.updatePosition()
    if ball.shouldScore:
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
