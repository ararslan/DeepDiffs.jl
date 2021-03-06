@testset "Display tests" begin
    # check dictionary print output. This is a little complicated because
    # the ordering isn't specified. To work around this we just split
    # up both into lines and make sure they have the same lines in some ordering.
    # This means we could possibly miss some errors, but it seems like a
    # reasonable compomise
    # expected should be a list of display lines within that dict
    function checkdictprint(output, expected)
        outlines = sort(split(output, "\n"))
        explines = sort(split(expected, "\n"))
        @test outlines == explines
    end
    orig_color = Base.have_color
    @testset "Array diffs print correctly" begin
        d1 = deepdiff([1, 2, 7, 3], [2, 3, 4, 1, 2, 3, 5])
        d2 = deepdiff([1], [2])

        buf = IOBuffer()
        eval(Base, :(have_color=true))
        # in 0.6 colored output is no longer bold as of PR #18628
        if VERSION < v"0.6.0-dev.1574"
            expected1 = """
                [[1m[32m2[0m[1m[32m, [0m[1m[32m3[0m[1m[32m, [0m[1m[32m4[0m[1m[32m, [0m[0m1[0m, [0m2[0m, [1m[31m7[0m[1m[31m, [0m[0m3[0m, [1m[32m5[0m]"""
            expected2 = """[[1m[31m1[0m[1m[31m, [0m[1m[32m2[0m]"""
        else
            expected1 = """
                [[32m2[39m[32m, [39m[32m3[39m[32m, [39m[32m4[39m[32m, [39m[0m1, [0m2, [31m7[39m[31m, [39m[0m3, [32m5[39m]"""
            expected2 = """[[31m1[39m[31m, [39m[32m2[39m]"""
        end
        @testset "Color Diffs" begin
            display(TextDisplay(buf), d1)
            @test String(take!(buf)) == expected1
            display(TextDisplay(buf), d2)
            @test String(take!(buf)) == expected2
        end

        eval(Base, :(have_color=false))
        @testset "No-Color Diffs" begin
            display(TextDisplay(buf), d1)
            @test String(take!(buf)) == """
                [(+)2, (+)3, (+)4, 1, 2, (-)7, 3, (+)5]"""
            display(TextDisplay(buf), d2)
            @test String(take!(buf)) == """
                [(-)1, (+)2]"""
        end

        eval(Base, :(have_color=$orig_color))
    end

    @testset "Dict diffs print correctly" begin
        d = deepdiff(
            Dict(
                :a => "a",
                :b => "b",
                :c => "c",
                :list => [1, 2, 3],
                :dict1 => Dict(
                    :a => 1,
                    :b => 2,
                    :c => 3
                ),
                :dict2 => Dict(
                    :a => 1,
                    :b => 2,
                    :c => 3
                )
            ),
            Dict(
                :a => "a",
                :b => "d",
                :e => "e",
                :list => [1, 4, 3],
                :dict1 => Dict(
                    :a => 1,
                    :b => 2,
                    :c => 3
                ),
                :dict2 => Dict(
                    :a => 1,
                    :c => 4
                )
            ),
        )

        @testset "Color Diffs" begin
            eval(Base, :(have_color=true))
            buf = IOBuffer()
            display(TextDisplay(buf), d)
            # in 0.6 colored output is no longer bold as of PR #18628
            if VERSION < v"0.6.0-dev.1574"
                expected = """
                Dict(
                     :a => "a",
                     :dict1 => Dict(
                         :c => 3,
                         :a => 1,
                         :b => 2,
                     ),
                [1m[31m-    :c => "c",
                [0m     :list => [[0m1[0m, [1m[31m2[0m[1m[31m, [0m[1m[32m4[0m[1m[32m, [0m[0m3[0m],
                     :b => "[1m[31mb[0m[1m[32md[0m",
                     :dict2 => Dict(
                         :a => 1,
                [1m[31m-        :b => 2,
                [0m[1m[31m-        :c => 3,
                [0m[1m[32m+        :c => 4,
                [0m[1m[32m[0m     ),
                [1m[32m+    :e => "e",
                [0m)"""
            else
                expected = """
                Dict(
                     :a => "a",
                     :dict1 => Dict(
                         :c => 3,
                         :a => 1,
                         :b => 2,
                     ),
                [31m-    :c => "c",
                [39m     :list => [[0m1, [31m2[39m[31m, [39m[32m4[39m[32m, [39m[0m3],
                     :b => "[31mb[39m[32md[39m",
                     :dict2 => Dict(
                         :a => 1,
                [31m-        :b => 2,
                [39m[31m-        :c => 3,
                [39m[32m+        :c => 4,
                [39m[32m[39m     ),
                [32m+    :e => "e",
                [39m)"""
            end
            # This test is broken because the specifics of how the ANSI color
            # codes are printed change based on the order, which changes with
            # different julia versions.
            @test_skip String(take!(buf)) == expected
        end
        @testset "No-Color Diffs" begin
            eval(Base, :(have_color=false))
            buf = IOBuffer()
            display(TextDisplay(buf), d)
            expected = """
            Dict(
                 :a => "a",
                 :dict1 => Dict(
                     :c => 3,
                     :a => 1,
                     :b => 2,
                 ),
            -    :c => "c",
                 :list => [1, (-)2, (+)4, 3],
                 :b => "{-b-}{+d+}",
                 :dict2 => Dict(
                     :a => 1,
            -        :b => 2,
            -        :c => 3,
            +        :c => 4,
                 ),
            +    :e => "e",
            )"""
            checkdictprint(String(take!(buf)), expected)
        end
        eval(Base, :(have_color=$orig_color))
    end

    @testset "single-line strings display correctly" begin
        # this test is just to handle some cases that don't get exercised elsewhere
        diff = deepdiff("abc", "adb")
        buf = IOBuffer()
        eval(Base, :(have_color=false))
        display(TextDisplay(buf), diff)
        @test String(take!(buf)) == "\"a{+d+}b{-c-}\""
        eval(Base, :(have_color=true))
    end

    @testset "Multi-line strings display correctly" begin
    s1 = """
        differences can
        be hard to find
        in
        multiline
        output"""
    s2 = """
        differences can
        be hurd to find
        multiline
        output"""
    diff = deepdiff(s1, s2)
    buf = IOBuffer()
    @testset "Color Display" begin
        eval(Base, :(have_color=true))
        # in 0.6 colored output is no longer bold as of PR #18628
        if VERSION < v"0.6.0-dev.1574"
            expected = """
            \"\"\"
              differences can
            [1m[31m- be hard to find[0m
            [1m[31m- in[0m
            [1m[32m+ be hurd to find[0m
              multiline
              output\"\"\""""
        else
            expected = """
            \"\"\"
              differences can
            [31m- be hard to find[39m
            [31m- in[39m
            [32m+ be hurd to find[39m
              multiline
              output\"\"\""""
        end
        display(TextDisplay(buf), diff)
        @test String(take!(buf)) == expected
    end
    @testset "No-Color Display" begin
        eval(Base, :(have_color=false))
        display(TextDisplay(buf), diff)
        @test String(take!(buf)) == """
        \"\"\"
          differences can
        - be hard to find
        - in
        + be hurd to find
          multiline
          output\"\"\""""
    end
    eval(Base, :(have_color=$orig_color))
    end
end
