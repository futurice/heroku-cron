# heroku-cron

## Why?

From https://devcenter.heroku.com/articles/scheduler

> Scheduler is a best-effort service. There is no guarantee that jobs will execute at their scheduled time, or at all.

*heroku-cron* is a simple kind-of [*custom-clock process*](https://devcenter.heroku.com/articles/scheduled-jobs-custom-clock-processes),
which one can use to run shell commands (which could schedule jobs, or do work themselves) a la cron.

## Building

You'll need docker to heroku compatible binary. To perform build just `./build.sh`.
