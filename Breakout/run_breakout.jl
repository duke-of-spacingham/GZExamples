import Pkg
Pkg.add("GameZero")
Pkg.add("Colors")

using GameZero
using Colors
rungame("Breakout.jl")
#rungame("Breakout_downgraded.jl")