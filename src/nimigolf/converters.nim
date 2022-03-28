import nico
import nico/vec

converter v2iToTuple*(v: Vec2i): tuple[x, y: int] =
  result = (v.x, v.y)

converter tupleInttoPint*(t: tuple[x, y: int]): tuple[x, y: Pint] =
  result = (t[0].Pint, t[1].Pint)

converter IntInttoVec2f*(t: (int,int)): Vec2f =
  result = vec2f(t[0], t[1])
