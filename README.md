# Conway's Game of Life

This is [Conway's Game-Of-Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) simulator.


## Statistics
The bottom row of the screen shows some statistics. The first valus is the generation
number; it increases by one for each generation.

The second number is the population count, i.e. the number of alive cells.

The remaining numbers are counting the number of pairwise alive cells, separated by a
given horizontal distance.

In math notation, the values are defined as

M\_k = SUM\_i X\_i \* X\_(i+k)

where X\_i is 1 for an alive cell and 0 for a dead cell. k is the distance.

From these numbers its possible to calculate the auto-correlation numbers by the following
formula:

rho\_k = (N \* M\_k - M\_0^2) / (M\_0 \* (N - M\_0))

It can be shown that |rho\_k| <= 1.

In fact, if the pattern consists of entirely alive cells on the left and entirely dead
cells on the right, then we have maximum correlation, and rho\_k = 1.
Alternatively, if the pattern consists of entirely alternating alive and dead cells, then
we have minimum correlation (or maximum anti-correlation), and rho\_k = -1.

### Results with 100 x 100, and initial density of 0.15

time =   2223 +/- 1609
dens =  0.028 +/- 0.003
rho1 =  0.284 +/- 0.029
rho2 =  0.088 +/- 0.018
rho3 =  0.019 +/- 0.014
rho4 = -0.012 +/- 0.010

### Results with 200 x 200, and initial density of 0.15

time =   3956 +/- 1856
dens =  0.028 +/- 0.002
rho1 =  0.285 +/- 0.015
rho2 =  0.088 +/- 0.008
rho3 =  0.019 +/- 0.006
rho4 = -0.011 +/- 0.006

### Results with 300 x 300, and initial density of 0.15

time =   4815 +/- 1591
dens =  0.028 +/- 0.002
rho1 =  0.284 +/- 0.010
rho2 =  0.091 +/- 0.005
rho3 =  0.017 +/- 0.004
rho4 = -0.011 +/- 0.004

### Results with 400 x 400, and initial density of 0.15

time =   5626 +/- 1648
dens =  0.028 +/- 0.001
rho1 =  0.284 +/- 0.007
rho2 =  0.090 +/- 0.004
rho3 =  0.017 +/- 0.003
rho4 = -0.011 +/- 0.003

