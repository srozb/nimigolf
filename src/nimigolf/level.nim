import os
import strutils
import nico
import nico/vec
import consts
import base

type
  TerrainType = enum
    tGrass, tSand

var
  curMap*, loadedLevels*: int
  startPos*, holePos*: Vec2i

proc center*(v: Vec2i): Vec2i =  # TODO: Refactor
  result = vec2i(v.x - TS div 2, v.y - TS div 2)

proc placeOnTile(self: var Vec2i, tx, ty: Pint) {.inline.} =
  # Sets the objects position to a center of given tile
  # let pos = mapToPixel(tx, ty)  # TODO
  self.x = (tx * TS) + TS/2
  self.y = (ty * TS) + TS/2

proc loadMaps*() =
  for mFile in walkPattern("assets/levels/*.json"):
    newMap(curMap, MAPW, MAPH, TS, TS)
    loadMap(curMap, mFile.split("/", 1)[1])
    curMap.inc
    loadedLevels.inc
  curMap = 0

proc terrainType(self: Obj, crn: TileCorner): TerrainType =
  result = tGrass
  let tileType = mget(self.centerTile[0], self.centerTile[1])
  # debug "pos: " & $x & " " & $y & " tileType: " & tileType.repr & " Corner: " & crn.repr
  if (tileType in SAND) or 
    (tileType in SAND_LEFT and crn in [q3, q4]) or 
    (tileType in SAND_RIGHT and crn in [q1, q2]) or
    (tileType in SAND_UP and crn in [q1, q4]) or
    (tileType in SAND_DOWN and crn in [q2, q3]) or
    (tileType in SAND_Q1 and crn == q1) or
    (tileType in SAND_Q2 and crn == q2) or
    (tileType in SAND_Q3 and crn == q3) or
    (tileType in SAND_Q4 and crn == q4) or
    (tileType in SAND_INV_Q1 and crn != q1) or
    (tileType in SAND_INV_Q2 and crn != q2) or
    (tileType in SAND_INV_Q3 and crn != q3) or
    (tileType in SAND_INV_Q4 and crn != q4)
    :
    return tSand

proc terrainMod*(self: Obj): float =
  result = 1.0
  if terrainType(self, self.tileCorner) == tSand:
    return SAND_MOD

proc resetLevel*() =
  setMap(curMap)

  for y in 0..<MAPH:
    for x in 0..<MAPW:
      case mget(x, y)
      of 84:
        startPos.placeOnTile(x, y)
      of 94:
        holePos.placeOnTile(x, y)
      else:
        discard