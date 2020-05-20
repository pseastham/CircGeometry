using CircGeometry, Test

@testset "write_circ test" begin
    vf = 0.4
    n_bodies = 400
    material = MaterialParameters(vf,n_bodies)

    radius = 1.5
    center = Point(-0.5,1.0)
    outline = OutlineCircle(radius,center)

    between_buffer = compute_between_buffer(outline,material)
    ps = generate_porous_structure(outline,material,between_buffer)
    write_circ("test-data/test_file.circ",ps)
    save_image("test-data/test_file.svg","test-data/test_file.circ",outline)
end

@testset "csv_to_polygon test" begin
    plist = csv_to_polygon("test-data/car.txt")
    @test length(plist) == 19
    @test plist[5].x == 0.0639999744331845
end

@testset "read_in_circ test" begin
    radiusArr, xArr, yArr = CircGeometry.read_in_circ("test-data/circle.circ")
    @test length(radiusArr) == 400
    @test xArr[5] == -0.8808863280747441
end

# clean up for next test
rm("test-data/test_file.circ")
rm("test-data/test_file.svg")