# Stud.

I've complained for a long time that ruby's stdlib is pretty bad. 

It's missing tons of things I do all the time, like retrying on a failure,
supervising workers, resource pools, etc.

In general, I started exploring solutions to these things in code over in my
[software-patterns](https://github.com/jordansissel/software-patterns) repo.
This library (stud) aims to be a well-tested, production-quality implementation
of the patterns described in that repo.

For now, these all exist in a single repo because, so far, implementations of
each 'pattern' are quite small by code size.

## Features

* retry on failure, with back-off, where failure is any exception.
* generic resource pools
* supervising tasks
* tasks (threads that can return values, exceptions, etc)
* interval execution (do X every N seconds)

## TODO:

* Make sure all things are documented. rubydoc.info should be able to clearly
  show folks how to use features of this library.
* Add tests to cover all supported features.
