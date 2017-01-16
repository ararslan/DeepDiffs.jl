@testset "arrays can be diffed" begin
    a1 = [1, 2, 3, 4]

    # one number changed
    @test deepdiff(a1, [1, 7, 3, 4]) == ([2], [2])

    # removed from middle
    @test deepdiff(a1, [1, 3, 4]) == ([2], [])

    # removed from beginning
    @test deepdiff(a1, [2, 3, 4]) == ([1], [])

    # removed from end
    @test deepdiff(a1, [1, 2, 3]) == ([4], [])

    # added to end
    @test deepdiff(a1, [1, 2, 3, 4, 5]) == ([], [5])

    # added to beginning
    @test deepdiff(a1, [0, 1, 2, 3, 4]) == ([], [1])

    # two additions
    @test deepdiff(a1, [1, 4, 2, 5, 3, 4]) == ([], [2, 4])

    # two removals
    @test deepdiff(a1, [2, 4]) == ([1, 3], [])
end
