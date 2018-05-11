breed [pools pool]

breed [investors investor]


pools-own [
  pool-number
  max-payoff
  probability-payoff
  payoffs
  numbers
  total-payoff
]

investors-own [
  wealth
  predictors
  my-payoffs
  my-choices
  sum-squares-error
]


to setup
  clear-all
  let next-pool 0
  create-ordered-pools 3 [
    fd 1
    set shape "face neutral"
    set pool-number next-pool
    if pool-number = POOL-STABLE [
      set color green
      set max-payoff 1
      set probability-payoff 1.0000001  ;; force payoff (probably not needed, but roundoff...)
    ]
    if pool-number = POOL-LOW [
      set color yellow
      set max-payoff max-payoff-low
      set probability-payoff p-payoff-low
    ]
    if pool-number = POOL-HIGH [
      set color red
      set max-payoff max-payoff-high
      set probability-payoff p-payoff-high
    ]
    set payoffs []
    set numbers []
    set next-pool next-pool + 1
    set total-payoff 0
  ]

  create-ordered-investors n-investors [
    set wealth 0
    set predictors map [-> linear-predictor INIT [] [] [] [] [] ] range n-predictors
    set my-payoffs []
    fd 15
    set shape "fish"
    let pool-index (1 + random-tower (list p-start-low p-start-high)) mod 3
    create-link-with one-of pools with [pool-number = pool-index]
    set my-choices (list pool-index)
    colourize
  ]
  reset-ticks
end



to go
  if ticks > n-ticks [stop]
  let low-payoff []
  let high-payoff []
  let low-number []
  let high-number[]
  let low-return 0
  let high-return 0
  ask pools [
    let r random-float 1
    let mypayoff ifelse-value (r < probability-payoff) [max-payoff][0]
    set shape ifelse-value (r < probability-payoff) ["face happy"]["face sad"]
    let n-members count link-neighbors
    if n-members > 0 and probability-payoff < 1 [set mypayoff mypayoff / n-members]
    set numbers fput n-members numbers
    set payoffs fput mypayoff payoffs
;    output-print (list mypayoff n-members)
    if pool-number = POOL-LOW [
      set low-payoff  payoffs
      set low-number numbers
      set low-return estimate-return payoffs numbers
    ]
    if pool-number = POOL-HIGH [
      set high-payoff  payoffs
      set high-number numbers
      set high-return estimate-return payoffs numbers
    ]
    set total-payoff total-payoff + mypayoff * n-members
  ]

;  output-print "---------------"
;  output-print low-number
;  output-print high-number

  ;; Use links to find out how much current pool will pay each onvestor
  ask investors [
    let delta-wealth 0
    ask one-of in-link-neighbors [set delta-wealth item 0 payoffs]
    set wealth wealth + delta-wealth
    set my-payoffs fput delta-wealth my-payoffs
  ]

  ;; Scale wealth for display

  let richest investors with-max [wealth]
  let max-wealth 0
  ask one-of richest [set max-wealth wealth]
  ask investors [
    set size max (list 2 (5 * round wealth / max (list 1 max-wealth)))
  ]

  ask investors [  ;; Select best pool
    let prediction (runresult (item 0 predictors) PREDICT low-payoff high-payoff low-number high-number)
    let recommended-pool item 0 prediction
    let predicted-benefit item 1 prediction
;    output-print (list "recommended pool" recommended-pool "predicted benefit" predicted-benefit my-choices)
     ;; If pool different, consider whether to change (tau)
    ifelse recommended-pool = item 0 my-choices [
      set my-choices fput recommended-pool my-choices
    ][
      if benefit-weight * predicted-benefit  > random-float tau [
        set wealth wealth - tau
        set my-choices fput recommended-pool my-choices
        ask one-of my-out-links [die]
        create-link-with one-of pools with [pool-number = recommended-pool]
        colourize
      ]
    ]
  ]

  ;; Breed predictors

  ask investors [
    let offspring map [predictor -> (runresult predictor CLONE low-payoff high-payoff low-number high-number)] predictors
    if is-anonymous-reporter? item 0 offspring  [set predictors sentence predictors offspring]
  ]

  ask investors [
    let indices range length predictors
    let scores-with-indices (map [[predictor index] -> (list (runresult predictor EVALUATE low-payoff high-payoff low-number high-number) index) ] predictors indices)
    let scores-sorted-with-indices sort-by [[l1 l2]-> item 0 l1 < item 0 l2] scores-with-indices  ;; sort by evaulation score
    set sum-squares-error item 0 (item 0 scores-sorted-with-indices)
    let indices-sorted-by-scores map [pair -> item 1 pair] scores-sorted-with-indices
    let culled-indices sublist indices-sorted-by-scores 0 n-predictors
    set predictors map [index -> item index predictors] culled-indices
  ]
  tick
end

to colourize
  let new-color 0
  ask one-of in-link-neighbors [set new-color color]
  set color new-color
end

to-report random-tower [probabilities]
  let i 0
  let selector random-float 1
  let threshold item i probabilities
  while [i < length probabilities][
    if selector < threshold [report i]
    set i i + 1
    if i < length probabilities [set threshold threshold + item i probabilities]
  ]
  report i
end

to-report linear-predict-count [counts coefficients]
  let result 0
  let i  0
  while [i < length counts and i < length coefficients] [
    set result result + (item i coefficients) * (item i counts)
    set i i + 1
  ]
  report int min (list n-investors abs result)
end

to-report linear-predictor [function low-payoff high-payoff low-number high-number coefficients]
  if function = INIT [
    let my-coefficients map [r -> -1 + 2 * random-float 1] range (1 + random n-coefficients)
    report  [[func a b c d] -> linear-predictor func a b c d my-coefficients]
  ]

  if function = PREDICT [
    let estimated-total-return-low estimate-return low-payoff low-number
    let estimated-total-return-high estimate-return high-payoff high-number
    let predicted-low-length linear-predict-count low-number coefficients
    let predicted-high-length linear-predict-count high-number coefficients
    let predicted-return-low estimated-total-return-low / (predicted-low-length + 1)
    let predicted-return-high estimated-total-return-high / (predicted-high-length + 1)
;    output-print coefficients
;    output-print (list "Low" "estimated total return" estimated-total-return-low "predicted length" predicted-low-length "predicted return" predicted-return-low)
;    output-print (list "High" "estimated total return" estimated-total-return-high "predicted length" predicted-high-length "predicted return" predicted-return-high)
    let recommended-pool POOL-STABLE
    let estimated-return 1
    if predicted-return-low > estimated-return[
      set recommended-pool POOL-LOW
      set estimated-return predicted-return-low
    ]
    if predicted-return-high > estimated-return[
      set recommended-pool POOL-HIGH
      set estimated-return predicted-return-high
    ]
    report (list recommended-pool estimated-return)
  ]

  if function = CLONE [
    let my-coefficients create-new-coefficients coefficients
    report  [[func a b c d] -> linear-predictor func a b c d my-coefficients]
  ]

  if function = EVALUATE [
    set sum-squares-error 0
    let i 0
    let len length low-number
    while [i < n-history and i < len - 1][
      let historical-low item i low-number
      let historical-high item i high-number
      set i i + 1
      let predicted-low-length linear-predict-count (sublist low-number i len) coefficients
      let predicted-high-length linear-predict-count (sublist high-number i len) coefficients
      let diff-low predicted-low-length - historical-low
      set sum-squares-error sum-squares-error + diff-low * diff-low
      let diff-high predicted-high-length - historical-high
      set sum-squares-error sum-squares-error + diff-high * diff-high
    ]

    report sum-squares-error
  ]

  report NOTHING
end

to-report  create-new-coefficients [coefficients]
  let len new-length coefficients
  if len < length coefficients [report mutate remove-item len coefficients]
  if len > length coefficients [report mutate lput 0.0 coefficients]
  report mutate coefficients
end

to-report mutate [coefficients]
  report map [c -> c + random-normal 0 0.1] coefficients   ;; FIXME - sigma
end

to-report new-length [coefficients]
  let result -1
  while [result < 1 or result > n-coefficients] [
    let r  random-float 1
    ifelse r < 1.0 / 3.0 [
      set result length coefficients - 1
    ][
      ifelse r < 2.0 / 3.0 [
        report length coefficients
      ][
        set result length coefficients + 1
    ]]

  ]
  report result
end


to-report estimate-return [mypayoffs mynumbers]
  let weighted-payoffs reduce + (map [[a b]-> a * max (list 1 b)] mypayoffs mynumbers)
  report weighted-payoffs / max (list 1 length mypayoffs)
end

to-report census [pool-no]
  let mypools pools with [pool-number = pool-no]
  report  ifelse-value (ticks > 0) [sum [item 0  numbers] of mypools][0]
end

to-report NOTHING
  report -1
end

to-report INIT
  report  0
end

to-report PREDICT
  report  INIT + 1
end

to-report CLONE
  report  PREDICT + 1
end

to-report EVALUATE
  report  CLONE + 1
end

to-report  POOL-STABLE    ;; Index used for stable pool
  report 0
end

to-report    POOL-LOW      ;; Index used for low risk pool
  report 1
end

to-report    POOL-HIGH     ;; Index used for low risk pool
  report 2
end

;; Copyright (c) 2018 Simon Crase - see info tab for details of licence
@#$#@#$#@
GRAPHICS-WINDOW
244
10
713
480
-1
-1
13.97
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
5
260
69
293
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
142
260
205
293
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
72
260
135
293
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
2
10
116
43
p-payoff-low
p-payoff-low
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
125
12
238
45
p-payoff-high
p-payoff-high
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
3
53
117
86
max-payoff-low
max-payoff-low
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
121
52
240
85
max-payoff-high
max-payoff-high
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
5
97
103
130
p-start-low
p-start-low
0
1
0.1
.01
1
NIL
HORIZONTAL

SLIDER
124
95
229
128
p-start-high
p-start-high
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
6
141
98
174
n-investors
n-investors
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
121
140
219
173
n-ticks
n-ticks
0
1000
100.0
5
1
NIL
HORIZONTAL

SLIDER
7
187
99
220
tau
tau
0
20
1.0
1
1
NIL
HORIZONTAL

PLOT
10
310
210
460
Spread
Wealth
Count
0.0
10.0
0.0
10.0
true
false
"set-plot-pen-mode 1\nset-plot-x-range 0 250\nset-plot-y-range 0 5\nset-histogram-num-bars 20" ""
PENS
"default" 1.0 0 -13345367 true "" "histogram [wealth] of investors"

MONITOR
8
477
111
522
Average Wealth
mean [wealth] of investors
0
1
11

MONITOR
122
477
208
522
Sigma
standard-deviation [wealth] of investors
1
1
11

SLIDER
725
10
826
43
n-coefficients
n-coefficients
1
25
6.0
1
1
NIL
HORIZONTAL

SLIDER
842
13
962
46
n-predictors
n-predictors
0
25
11.0
1
1
NIL
HORIZONTAL

SLIDER
990
20
1082
53
n-history
n-history
0
25
10.0
1
1
NIL
HORIZONTAL

PLOT
739
63
939
213
Prediction errors
NIL
Sum squared error
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5825686 true "" "plot mean [sum-squares-error] of investors"

PLOT
741
254
941
404
Wealth
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"wealth" 1.0 0 -11221820 true "" "plot sum [wealth] of investors"
"payout" 1.0 0 -5825686 true "" "plot sum[total-payoff] of pools"
"Switching" 1.0 0 -955883 true "" "plot (sum[total-payoff] of pools - sum [wealth] of investors )"

PLOT
970
239
1170
389
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -10899396 true "" "plot census POOL-STABLE"
"pen-1" 1.0 0 -1184463 true "" "plot census POOL-LOW"
"pen-2" 1.0 0 -2674135 true "" "plot census POOL-HIGH"

SLIDER
1004
82
1176
115
benefit-weight
benefit-weight
0
1
0.25
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
