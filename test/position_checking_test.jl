using CircGeometry, Test

p1 = Point(0.0,0.0); q1 = Point(0.0,1.0)
p2 = Point(-0.5,0.5); q2 = Point(0.5,0.5)
@testset "do_intersect tests" begin 
    @test CircGeometry.do_intersect(p1,q1,p2,q2) == true
    @test CircGeometry.do_intersect(p1,p2,q1,q2) == false
end

z = Point(0.5+Float64(pi),1.5+Float64(pi))
@testset "get_orientation tests" begin
    @test CircGeometry.get_orientation(p2,q1,z) == 0
    @test CircGeometry.get_orientation(p2,z,q1) == 0
    @test CircGeometry.get_orientation(z,p2,q1) == 0
    @test CircGeometry.get_orientation(p1,q1,Point(1.0,0.0)) == 1
    @test CircGeometry.get_orientation(p1,q1,Point(-1.0,0.0)) == 2
end

a = Point(13.2,12.3)
b = Point(1.0+5*eps(),1.0)
c = Point(-1.0,0.0)
circlewall = CircGeometry.CircleWall(Point(0.0,0.0),1.0)
lwall1 = CircGeometry.LineWall(Point(-1.0,1.0),Point(1.0,1.0))
lwall2 = CircGeometry.LineWall(Point(-1.0,-1.0),Point(-1.0,1.0))
@testset "is_point_in_wall tests" begin
    @test CircGeometry.is_point_in_wall(q1,circlewall) == true
    @test CircGeometry.is_point_in_wall(p2,circlewall) == false
    @test CircGeometry.is_point_in_wall(a,circlewall) == false

    @test CircGeometry.is_point_in_wall(q1,lwall1) == true
    @test CircGeometry.is_point_in_wall(p1,lwall1) == false
    @test CircGeometry.is_point_in_wall(b,lwall1) == false

    @test CircGeometry.is_point_in_wall(c,lwall2) == true
    @test CircGeometry.is_point_in_wall(p1,lwall2) == false
end