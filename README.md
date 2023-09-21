# GameZero.jl Examples

Example games for [GameZero.jl](https://github.com/aviks/GameZero.jl)


## Using

To play the games in this repo, see if they have a "rungame.jl" file.
If they do, simply run the game in the terminal, it will install any dependency it might have:
```
> julia rungame.jl
```

If there is no rungame.jl, start the Julia REPL and run commands such as these (this example uses the spaceships game):

```
pkg> add GameZero

julia> using GameZero

julia> GameZero.rungame("C:\\path\\to\\GZExamples\\Spaceship\\Spaceship.jl")

```

## Licenses
Each game is under a seperate license. Please check inside the directory for the correct one.
