Pubsub Worker
=============

Listens for Redis pub/sub messages and executes a script if an appropriate one
is found.

There are no retries. You only get one shot, do not miss your chance to blow, this
opportunity comes once in a lifetime yo.

Probably not worth using, but I'm using it.

It's multi-threaded, but it only has one worker thread, ¯\_(ツ)_/¯ nobody really knows why
