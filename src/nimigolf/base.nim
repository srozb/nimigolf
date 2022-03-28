import nico
import nico/vec
import consts
import converters

type
  TileCorner* = enum
    q1, q2, q3, q4

  Hitbox* = tuple
    x, y, w, h: int

  Obj* = ref object of RootObj
    pos*: Vec2f
    vel*: Vec2f
    res*: Vec2f
    hitbox*: Hitbox
    visible*: bool

method draw*(self: Obj) {.base.} =
  discard

method center*(self: Obj): Vec2f {.base inline.} =
  # Returns the object's center position
  result = vec2f(self.pos.x + (TS div 2), self.pos.y + (TS div 2))

method centerTile*(self: Obj): (Pint, Pint) {.base inline.} =
  # Returns the tile type where object resides (center of the object)
  result = pixelToMap(self.center.x, self.center.y)

method tilePos*(self: Obj): Vec2f {.base.} =
  # Returns object position relative to current map tile
  result = vec2f(self.center.x mod TS, self.center.y mod TS)

method tileCorner*(self: Obj): TileCorner {.base.} =
  # Returns which corner of the tile is being occupied by object
  result = q4
  if self.tilePos.x >= TS/2:
    if self.tilePos.y < TS/2:
      return q1
    else:
      return q2
  else:
    if self.tilePos.y >= TS/2:
      return q3

method reset*(self: Obj) {.base.} =
  discard

method stop*(self: Obj) {.base.} =
  # Stops the object movement
  self.vel = (0, 0)
