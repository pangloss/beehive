# Bee Colony Algorithm

This started out as a near-exact port of the C# code in <a href="http://msdn.microsoft.com/fr-fr/magazine/gg983491(en-us).aspx">this article</a>.

## What I've done so far

* Made a number of simple changes to it to make it more Rubyish.
* Renamed things a little. 
* I have tried to break apart the general algorithm from the Travelling
  Salesman example-specific code by moving that code into the
  TravellingSalesBee class. In fact there is very little
  problem-specific code in this example.
* Instead of statically configuring the algorithm, I've added some
  simple code that adjusts the configuration as it progresses toward a
  solution.
* Track some simple history and visually show what is actually
  happenning and how the configuration is affecting the algorithm

## Dynamic Configuration

* Start with a very high number of scout bees and rapidly reduce them as
  their usefulness decreases.
* Eliminate scouts entirely once it becomes virtually impossible for
  them to stumble upon a better path
* Start with a 0.0 error rate, then as a solution nears gradually raise
  the error rate as mutations become the primary source of progress.
* Gradually reduce the persuasion rate as the solution nears to try to
  keep multiple strategies in play as much as possible.

## Running it

The code requires Ruby 1.9.2 or preferably JRuby with the --1.9 option!
