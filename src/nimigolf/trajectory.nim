import strformat
import nico
import nico/vec
import base
import consts

type
  TrajectoryLine* = ref object of Obj
    frc*: Vec2f

proc newTrajectoryLine*(): TrajectoryLine =
  result = new TrajectoryLine

proc limited(self: Vec2f, limit = MAXVEL): Vec2f {.inline.} =
  result = self
  if result.length > limit:
    let limit_mp = limit / result.length
    result.x *= limit_mp
    result.y *= limit_mp

proc asVel*(self: TrajectoryLine, mp = MOUSE_MP): Vec2f =
  # Converts the visible trajectory line to the force vector (velocity)
  result = ((self.frc - self.pos) * mp).limited()

method draw*(self: TrajectoryLine) = 
  if self.visible:
    setColor(1)
    line(self.pos, self.pos + self.asVel * 1/MOUSE_MP)
    print(fmt"Force: {self.asVel.length:0.1f}", SCREENW-150, 32)