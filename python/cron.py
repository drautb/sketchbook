#!/usr/bin/env python3

import sched, time, datetime

scheduler = sched.scheduler(time.time, time.sleep)

def say_hi():
  print "%s: Hello!" % str(datetime.datetime.now())
  scheduler.enter(5, 1, say_hi, argument=())
  scheduler.run()

say_hi()
