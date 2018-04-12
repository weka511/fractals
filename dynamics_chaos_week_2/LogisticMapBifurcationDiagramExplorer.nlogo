globals[x r]


to create-map [#iterations #pts]
  ca
  crt 1 
  set r min-r
  let step (1.0 / world-width)  
  while [ r < max-r ] [
       set x 0.5
       repeat #iterations [set x ( r * x * (1 - x)) ] ;throw away some values, throw away more for finer resolution, throw away fewer for faster rendering
       repeat  #pts [
         
            ;the central equation
              set x ( r * x * (1 - x))      ;plot final points. continue iterating 
              
            ;use the values obtained above and scale them to fit the available viewing area
              
              let scaled-r convert-coordinate offset-adjusted-r r  r-range  world-width  ;value on horizontal axis
              let scaled-x convert-coordinate offset-adjusted-x x  x-range  world-height ;value on vertical axis
              
            ;plot the scaled values
              
              ask turtles [ setxy scaled-r scaled-x 
                            ask patch-here [set pcolor red]]
        ]
       
       ;move on to the next value of r
       
       set r r + step-size 
       ]
end





to-report r-range
  report max-r - min-r
end 

to-report offset-adjusted-r [#r]
  report #r - min-r
end 

to-report x-range
  report max-x - min-x
end 

to-report offset-adjusted-x [#x]
  ifelse #x > min-x and #x < max-x 
       [report #x - min-x]
       [report 0]
end 

to-report convert-coordinate [#coor #virtual-range #real-range]
   report (#coor / #virtual-range) * #real-range
end

to-report step-size  ;We want the step-size to match the world width. I use a world 2000 wide here so steps are 1/2000 
  report r-range / (world-width )
end 
  
  
  
to x-ray [#max-x #min-x #max-r  #min-r]   ;example  .6 .4 3.9 3.5   
  ask patches with [
    pycor < convert-coordinate #max-x x-range world-height and 
    pycor > convert-coordinate #min-x x-range world-height and
    pxcor < convert-coordinate #max-r r-range world-width and 
    pxcor > convert-coordinate #min-r r-range world-width    
    ] [set pcolor pcolor + 9.9] 
         
end 
@#$#@#$#@
GRAPHICS-WINDOW
6
133
2025
792
-1
-1
1.004
1
10
1
1
1
0
1
1
1
0
2000
0
625
0
0
0
ticks
15.0

BUTTON
458
91
524
124
Go
if min-r > max-r or min-x > max-x [user-message \"Check your slider values! Min values should be smaller than max values.\"]\n\n\ncreate-map num-iterations num-points\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
8
10
339
31
Logistic Map Bifurcation Explorer
16
95.0
1

SLIDER
715
60
887
93
min-r
min-r
0
3.8
3.48
.0000001
1
NIL
HORIZONTAL

TEXTBOX
765
15
995
71
These sliders control at what value of r is an area zoomed in on at values of x
11
0.0
1

BUTTON
1085
96
1152
129
Zoom
\nx-ray 0.6 0.45 3.9 3.5  ; max-x min-x max-r min-r\nwait 4\nset min-r 3.48\nset max-r 3.9\nset min-x 0.4\nset max-x 0.6\ncreate-map 1200 200 ;#iterations #plotted
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
715
95
887
128
max-r
max-r
1
4
3.9
.0000001
1
NIL
HORIZONTAL

SLIDER
890
95
1062
128
max-x
max-x
0
1
0.6
.0000001
1
NIL
HORIZONTAL

SLIDER
890
60
1062
93
min-x
min-x
0
.9
0.4
.0000001
1
NIL
HORIZONTAL

BUTTON
457
24
523
57
Setup
  set min-r 0\n  set max-r 4\n  set min-x 0\n  set max-x 1\n  create-map 1000 100
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
1154
96
1221
129
Zoom-2
\nx-ray 0.555 0.551 3.6 3.55  ; max-x min-x max-r min-r\nwait 4\nset min-r 3.53\nset max-r 4\nset min-x 0.551\nset max-x 0.555\ncreate-map  10000 2000  ;#iterations #plotted
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
309
25
459
53
Click Setup to generate the logistic map
11
0.0
1

SLIDER
540
95
713
128
num-points
num-points
100
3000
1350
50
1
NIL
HORIZONTAL

SLIDER
540
60
713
93
num-iterations
num-iterations
1000
100000
11700
100
1
NIL
HORIZONTAL

TEXTBOX
9
37
275
113
* The world window for this model is uncommonly large. In order to view the logistic map created here, scroll around and explore the interface. This model is also comparatively slow to other models. Some actions take several moments before points begin being mapped in the world window.
10
0.0
1

TEXTBOX
309
86
459
156
After adjusting the sliders to the left Click Go to explore the logistic map
11
0.0
1

TEXTBOX
545
15
705
71
These sliders control number of iterations and the number of points to be plotted
11
0.0
1

TEXTBOX
1095
10
1245
85
Two custom zoomed in areas have been offered here to investigate the self-referential behavior of the logistic map 
11
0.0
1

TEXTBOX
9
38
275
117
* The world window for this model is uncommonly large. In order to view the logistic map created here, scroll around and explore the interface. This model is also comparatively slow to other models. Some actions take several moments before points begin being mapped in the world window.
10
0.0
1

@#$#@#$#@
## WHAT IS IT?

The bifurcation diagram shows the patterns generated by plotting the final values in many number sequences. The sequences are the result of iterating the logistic map.
In this equation the expression on the right is evaluated the first time through with x equal to an initial value that is provided. r is a parameter that is provided. The result of evaluating the expression is x'. On the second and subsequent iterations, the value of x is taken from the PREVIOUS value of x'. See the spreadsheet below.

## HOW IT WORKS
The difference equation: x' = rx(1-x) outputs a sequence of numbers. As we experiment with different values of r, we see that the sequence generated falls into different patterns or no pattern at all. 

This model works by iterating over the various values of x in the create-map procedure. The first 200 values are discarded. Subsequent values are used to color patches on the world. A turtle moves to the patch location (setxy) and colors the patch red. Because the patches are very small, a high resolution plot emerges. 

## HOW TO USE IT
Setup button generates the basic plot and Zoom buttons allow users to see some of the fine structure of the logistic map. Advanced explorations are possible using the sliders below to set a particular window of x and r values. This features allows for magnification of particular areas of interest. 


## THINGS TO NOTICE

Notice that there are region of order and regions of disorder in the map as r increases. 

## THINGS TO TRY
Change the number of values that are discarded in the create-map procedure. Change the number of values that are plotted. Does this make a difference?

## EXTENDING THE MODEL

Create turtles that label the values at key places in the map. 

## NETLOGO FEATURES

This model has some code that allows users to zoom in on particular areas of the logistic map. This involves having a "virtual" coordinate system mapped on to the real coordinate system provided by the World. Implementing this requires the same "code" that teachers use when re-adjusting test scores to grade on a curve. The proportionality
virtual grade / range of virtual grades  =  actual score / range of actual scores is the key to getting this to work. 


## CREDITS AND REFERENCES

This model is part of the Fractals series of the Complexity Explorer project.  
 
Main Author:  John Balwit

Contributions from: Eben Wood

Netlogo:  Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## HOW TO CITE

If you use this model, please cite it as: Affine Transformations model, Complexity Explorer project, http://complexityexplorer.org

## COPYRIGHT AND LICENSE

Copyright 2013 Santa Fe Institute.  

This model is licensed by the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 License ( http://creativecommons.org/licenses/by-nc-nd/3.0/ ). This states that you may copy, distribute, and transmit the work under the condition that you give attribution to ComplexityExplorer.org, and your use is for non-commercial purposes.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
