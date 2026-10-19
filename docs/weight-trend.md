# Weight trend: rolling mean, no EMA (#45)

The weight chart smooths the log with a trailing rolling mean over seven
calendar days (`lib/core/utils/calc/weight_moving_average.dart`). The tests in
`test/unit_test/weight_moving_average_test.dart` pin how it behaves on sparse
logs:

- **Gaps longer than the window** start the smoothing afresh: readings before
  the gap never leak into points after it, and the first reading after the gap
  stands alone (dropped at the default `minSamples: 2`).
- **Several readings on one day** all count; the app stores one reading per day
  anyway (`WeightLogDataSource` keys by date), so this only matters for
  imported data.
- **A single reading** gives no smoothed point by default and its own value at
  `minSamples: 1`.
- **Calendar boundaries** (month, year, daylight saving) are handled by
  building the window start from year/month/day, not from a fixed duration.

## Why not an exponential moving average

An EMA reacts faster and needs no window, but its weight per reading depends
on how often the user weighs in: with daily readings a smoothing factor of
0.1 spans about ten days, with weekly readings about ten weeks. A time-aware
EMA (decay by elapsed days) fixes that at the cost of a tuning constant the
user cannot see. The calendar-day rolling mean already copes with irregular
logging (a window holds whatever readings fall into it), is easy to explain
("average of the last seven days") and matches what the Trends forecast reads.
So the rolling mean stays; an EMA can be revisited if users ask for a faster
reacting line.

Observation: the chart connects smoothed points across a gap with a straight
line. That is how the raw readings are drawn too and is left as it is.
