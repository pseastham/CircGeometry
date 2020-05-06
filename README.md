# CircGeometry.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://pseastham.github.io/CircGeometry.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://pseastham.github.io/CircGeometry.jl/dev)
[![Build Status](https://travis-ci.com/pseastham/CircGeometry.jl.svg?branch=master)](https://travis-ci.com/pseastham/CircGeometry.jl)
[![Codecov](https://codecov.io/gh/pseastham/CircGeometry.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pseastham/CircGeometry.jl)


## Installation

CircGeometry.jl is an unregistered julia package.  To install StokesParticles.jl using the REPL, type

`pkg> add https://github.com/pseastham/CircGeometry.jl`

To enter the Pkg environment from the REPL, type `]`.

## Use

CircGeometry.jl takes in some basic information related to the object your are trying to approximate with "filling circles", and exports a file in the custom `circ` format. 

Geometrie are defined by their type (circle, rectangle, or arbitrary polygon), volume fraction, and number of filling circles. The time it takes to generate a circ file will depend on these parameters, but will generally only be a couple minutes for production-level files (e.g. volume fraction of 0.4 with 800 circles).

## Examples

Here are some visualizations of the circ files with accompanying "outline" (dash).