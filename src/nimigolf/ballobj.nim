import base
import consts
import nico
import nico/vec
import level
import trajectory

type
  BounceType* = enum
    bHor, bVer, bDiagSl, bDiagBSl

  Ball* = ref object of Obj
    id*, shots*: int
    origin: Vec2f

method reset*(self: Ball) =
  # Resets the ball position
  self.visible = true
  self.pos = startPos.center.vec2f
  self.stop

proc newBall*(): Ball = 
  result = new Ball
  result.hitbox.x = TS div 2
  result.hitbox.w = 6
  result.hitbox.y = TS div 2
  result.hitbox.h = 6
  result.id = 0
  # result.id = players
  # players.inc
  result.reset

method draw*(self: Ball) =  # TODO: create generic base method
  if self.visible:
    spr(73+self.id, self.pos.x, self.pos.y)

proc getPlayer*(self: Ball): string =
  return "Player " & $(self.id + 1)

proc getGameScoreCap*(self: Ball): string =
  return self.getPlayer() & ": " & $self.shots

proc inHole*(self: Ball): bool {.inline.} =
  return dist(self.center, holePos.vec2f) <= 2

proc bounce(self: Ball, bounces: var seq[BounceType]) =
  while bounces.len > 0:
    case bounces.pop
    of bHor:
      self.vel.y *= -BOUNCY
      self.res.y *= -1
    of bVer:
      self.vel.x *= -BOUNCY
      self.res.x *= -1
    of bDiagSl:
      (self.vel.x, self.vel.y) = (self.vel.y * -BOUNCY, self.vel.x * -BOUNCY) 
      (self.res.x, self.res.y) = (self.res.y * -1, self.res.x * -1) 
    of bDiagBSl:
      (self.vel.x, self.vel.y) = (self.vel.y * BOUNCY, self.vel.x * BOUNCY)
      (self.res.x, self.res.y) = (self.res.y, self.res.x)

proc bounceIfCollision(self: Ball) =
  let
    ballTile = self.centerTile()
    curTile = mget(ballTile[0], ballTile[1])
    ballTilePos = self.tilePos()
  var bounces = newSeq[BounceType]()
  if curTile in HBOUNDS:
    bounces.add(bHor)
  elif curTile in VBOUNDS:
    bounces.add(bVer)
  elif curTile in DBOUNDS:
    bounces.add(bDiagSl)
  elif curTile in BDBOUNDS:
    bounces.add(bDiagBSl)
  elif curTile in HDBOUNDS and abs(ballTilePos.x + ballTilePos.y - TS) < 2:
    bounces.add(bDiagSl)
  elif curTile in HBDBOUNDS and abs(ballTilePos.x - ballTilePos.y) < 2:
    bounces.add(bDiagBSl)
  self.bounce(bounces)

proc turnNearHole(self: Ball) =
  if dist(self.center, holePos.vec2f) < 25:
    self.vel += (holePos.vec2f-self.center) / dist2(self.center, holePos.vec2f)

proc move(self: Ball) =
  # Move the ball accroding to the current velocity, 
  # simulate movement if velocity > threshold
  self.vel *= (DECCEL * self.terrainMod)
  if self.vel.length < 2.5:
    self.pos += self.vel
    self.bounceIfCollision()
    return
  let smplStep = 0.45f
  self.res = self.vel
  while self.res.length > smplStep:
    self.bounceIfCollision()
    approach(self.pos.x, self.pos.x+self.res.x, smplStep)
    approach(self.pos.y, self.pos.y+self.res.y, smplStep)
    approach(self.res.x, 0, smplStep)
    approach(self.res.y, 0, smplStep)

proc isMoving*(self: Ball): bool =
  return self.vel.length != 0

proc update*(self: Ball) =
  if not self.isMoving or not self.visible:
    return
  if self.vel.length < STOP_TH:
    self.stop()
    return
  self.move
  self.turnNearHole
  if self.inHole:
      self.visible = false

proc shoot*(self: Ball, tl: TrajectoryLine) =
  self.vel = tl.asVel
  self.shots.inc
