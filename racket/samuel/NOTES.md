Samuel
======

I was going to recreate the game using racket's `big-bang`, and then add networking as an exercise. However, David Vanderson's [Warp][1] doesn't use `big-bang`, and he uses the FFI to do socket stuff. I think he talked about it in his RacketCon presentation, but I don't remember the reasons.

Questions:
* Is `big-bang` not performant enough for multiplayer action games?
    - Still don't know, the talk didn't mention it.
* Why did he use the FFI for sockets?
    - He only used the FFI to configure a specific socket option. [Sauce][2]
* Why did he use DC for rendering?
    - It's fast? I don't know, it looks like it's just what was there. I get the impression he didn't know about `big-bang` at all. That being said, I think it would be harder to do his game under the constraints that `big-bang` imposes.
* Is his way the _best_ way to go? (If I want to do Greebles in Racket, should I follow suit?)

* Will using typed racket yield a significant performance increase?

# Networking Ideas

[This article][3] was really helpful too. I've already modfied the server to send world updates at fixed intervals, which has made the overall experience smoother. (Since I'm not flooding the network anymore.)

Clients still send commands as soon as things happen.

The issue I'm facing now is updating client B in client A's view.

Option #1 - Do nothing. This works, but is tough to play. Client B hops around everytime a world update is received.

Option #2 - Do client-side prediction for Client B. This works, but Client B still hops around, since Client A predicted that he would keep moving, but really he stopped after the last world update was sent. The severity of the hops is directly related to the interval between world updates, so it gets better if world updates are sent more frequently, but that may not be viable over the internet.

Option #3 - Time travel. The [article][3] talks about showing Client B in the past in Client A's view. This one makes more sense for FPS style games I think, where a bullet can reach a target instantaneously, so the server goes back in time to see if they were aiming properly.

For Samuel, (and Greebles) projectiles move slowly. (Arrows, blocks, etc.) So I think Option #2 makes the most sense. Clients can include a timestamp with messages...that way there isn't really a delay, the server can pick up where the client left off I think...

I still want to apply the [delta pattern][4] used in Quake 3.


[1]: https://github.com/david-vanderson/warp
[2]: http://macrologist.blogspot.com/2012/03/avoid-flushing-your-wire-protocols.html
[3]: http://www.gabrielgambetta.com/fast_paced_multiplayer.html
[4]: http://trac.bookofhook.com/bookofhook/trac.cgi/wiki/Quake3Networking