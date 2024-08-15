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

