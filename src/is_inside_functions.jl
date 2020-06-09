
"""
  is_inside_outline(fo,outline)

Checks whether filling object `fo` is inside the `outline` object. Special methods
called for circle, rectangle, and polygon outlines.
"""
function is_inside_outline(fo::FillingCircle{T},outline::OutlineCircle{T}) where T<:Real
  furthest_point = fo.radius + sqrt((fo.center.x-outline.center.x)^2 + (fo.center.y-outline.center.y)^2)
  return (furthest_point < outline.radius ? true : false)
end
function is_inside_outline(fo::FillingCircle{T},outline::OutlineRectangle{T}) where T<:Real
  if (fo.center.y + fo.radius) > outline.p2.y         # check top
      return false
  elseif (fo.center.y - fo.radius) < outline.p1.y     # check bottom
      return false
  end

  if (fo.center.x + fo.radius) > outline.p2.x         # check right
      return false
  elseif (fo.center.x - fo.radius) < outline.p1.x     # check left
      return false
  end

  return true
end
function is_inside_outline(fo::FillingCircle{T},outline::OutlinePolygon{T}) where T<:Real
  return is_inside_polygon(outline.pList, fo.center)
end

function is_inside_polygon(polygon::Vector{P}, p::P; extreme = Point(100_000.0, p.y)) where P<:Point
  n = length(polygon)
  # There must be at least 3 vertices in polygon
  if (n < 3); return false; end

  # Count intersections of the above line with sides of polygon
  count = 0
  for i=1:n
    next = mod(i,n)+1
    # Check if the line segment from 'p' to 'extreme' intersects
    # with the line segment from 'polygon[i]' to 'polygon[next]'
    if (do_intersect(polygon[i], polygon[next], p, extreme))
      # If the point 'p' is colinear with line segment 'i-next', then check if it lies on segment. 
      # If it lies, return true, otherwise false
      if (get_orientation(polygon[i], p, polygon[next]) == 0)
         return on_segment(polygon[i], p, polygon[next])
      end
      count += 1
    end
  end

  return (isodd(count) ? true : false)
end

function is_intersecting_walls(outline::O,fo::F) where {O<:AbstractOutlineObject,F<:AbstractFillingObject}
  for tw=1:length(outline.wlist)
    pointOnWall = get_nearest_point(fo.center,outline.wlist[tw])
    if is_point_in_wall(pointOnWall,outline.wlist[tw])
      Δx = pointOnWall.x - fo.center.x
      Δy = pointOnWall.y - fo.center.y
      dist = sqrt(Δx^2 + Δy^2)

      if dist < fo.radius
        return true
      end
    end
  end

  return false
end

""" 
  do_intersect(p1,q1,p2,q2)

Checks if the line segment p1 to q1 intersects line from p2 to q2. Returns
a bool.
"""
function do_intersect(p1::Point{T},q1::Point{T},p2::Point{T},q2::Point{T}) where T<:Real
    # Find the four orientations needed for general case
    o1 = get_orientation(p1, q1, p2)
    o2 = get_orientation(p1, q1, q2)
    o3 = get_orientation(p2, q2, p1)
    o4 = get_orientation(p2, q2, q1)

    # General case
    if (o1 != o2 && o3 != o4)
        return true
    else
        return false
    end
end

"""
  get_orientation(p,q,r)

Checks orientation of polygon p-q-r. Returns 0 for colinear, 
1 for clockwise, and 2 for counter-clockwise.
"""
function get_orientation(p::Point{T},q::Point{T},r::Point{T}) where T<:Real
    val = (q.y-p.y)*(r.x-q.x) - (q.x-p.x)*(r.y-q.y);

    if isapprox(val, 0; atol=eps(Float64), rtol=0)
      return zero(Int)
    end 

    return (val > 0) ? one(Int) : 2*one(Int) # clock- or counterclock-wise
end

function get_nearest_point!(point::Point{T},node::Point{T},wall::LineWall) where T<:Real
  px=node.x; py=node.y

  Ax=wall.nodes[1].x; Ay=wall.nodes[1].y
  Bx=wall.nodes[2].x; By=wall.nodes[2].y

  bx=px-Ax; by=py-Ay
  ax=Bx-Ax; ay=By-Ay

  ℓ2 = ax^2+ay^2

  dotprod = ax*bx + ay*by

  point.x = dotprod*ax/ℓ2 + Ax
  point.y = dotprod*ay/ℓ2 + Ay

  nothing
end
function get_nearest_point!(point::Point{T},node::Point{T},wall::CircleWall) where T<:Real
  px=node.x; py=node.y
  cx=wall.center.x; cy=wall.center.y
  r = wall.radius
  θ = atan(py-cy,px-cx)

  point.x = cx + r*cos(θ)
  point.y = cy + r*sin(θ)

  nothing
end
function get_nearest_point(node::Point{T},wall::W) where {T<:Real,W<:AbstractWall}
  point = Point(0.0,0.0)
  get_nearest_point!(point,node,wall)
  return point
end

"""
  is_point_in_wall(point,wall)

Checks whether `point` is on `wall`. Different methods for handling
circle and line walls. Returns a bool.
"""
function is_point_in_wall(point::Point{T},wall::LineWall{T}) where T<:Real
  return on_segment(wall.nodes[1],point,wall.nodes[2])
end
function is_point_in_wall(point::Point{T},wall::CircleWall{T}) where T<:Real
  cx = wall.center.x; cy=wall.center.y
  val = abs(wall.radius - sqrt((cx-point.x)^2 + (cy-point.y)^2))
  return isapprox(val, 0; atol=eps(Float64), rtol=0) ? true : false
end

"""
  on_segment(p,q,r)

Checks whether the point `q` is on the line segment from `p` to `r`.
Returns a bool.
"""
function on_segment(p::Point{T},q::Point{T},r::Point{T}) where T<:Real
  if abs(distance(p, q) + distance(q, r) - distance(p, r)) < eps()
    return true
  else
    return false
  end
end

function distance(a::Point{T},b::Point{T}) where T<:Real
  return sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end