extensions [array]

breed [cameras camera]
breed [baggages baggage]
breed [securities security] ;This is how we define new breeds
breed [criminals criminal]
breed [passengers passenger]
breed [trains train]
globals [platform-size track-size stairs-size bench-col] ;global variables
passengers-own [objective objective-number wants-to-exit visible seen money vulnerability aesthetic has-baggage carrying-baggage gait] ; features that passengers can be given
cameras-own [fov dis]
securities-own [objective objective-number at-platform moving seen-list has-baggage carrying-baggage gait actioning judgement] ; features that security can be given
patches-own [patch-type number visibility] ; features each of the pixels (patches) can be given
trains-own [max-carriages leaving arriving train-line-number current-carriages stop-tick passenger-count]
criminals-own [ objective objective-number money wants-to-exit visible seen seen-list has-baggage carrying-baggage gait victim-target] ; features that criminals can be given
baggages-own [owner]


to move-forward [x person]
  forward x
  let myx xcor
  let myy ycor
  let carrying carrying-baggage

  if has-baggage[
    if not carrying-baggage [
      let bag one-of baggages with [owner = person and distance person <= 2]
      if  not (bag = nobody) [
        if random-float 1 > chance-of-forget-bag [
       ask bag [
            create-link-with person]
          set carrying-baggage True
    ]]]
     ask link-neighbors [
         set xcor myx
         set ycor myy
    ]]


end

; sets the heading towards the nearest stair pixel and move towards it
to move-towards-the-stairs [person]
    ask person [
     let target-patch min-one-of (patches with [patch-type = "stairs"]) [distance myself] ;find the nearest stair pixel
     set heading towards  target-patch ; look at it
     move-forward 1 myself
  ] ; move to it
end



to sit [person]
  if random-float 1 < chance-of-putting-down-bag[
    ask my-links [
     die
    ]
    set carrying-baggage False
  ]

  set gait "sitting"
end

to stand [person]
   if random-float 1 < chance-of-putting-down-bag[
    ask my-links [
     die
    ]
        set carrying-baggage False
  ]
  set gait "standing"
end


to try-and-find-a-place-to-sit [person]
 let plat-num objective-number
  ifelse [pcolor] of patch-here = bench-col and not any? (other passengers-here) and number = plat-num [
  sit person
  ][
    carefully[
     let bench one-of patches with [pcolor = bench-col and  patch-type = "platform" and number = plat-num and not any? (other passengers-here) ]
      set heading towards bench
      move-forward 1 person ][
     find-a-place-to-stand person
    ]
  ]
end

to put-down-luggage [person]
  ask links [
   die
  ]

end
to find-a-place-to-stand [person]
  carefully [
  let plat-num objective-number
    ifelse any? (other passengers) in-radius 3 [
  let head  one-of patches  with [not any? (other passengers) in-radius 3 and patch-type = "platform" and number = plat-num  ]
  set heading head
  move-forward 1 person][
     if [number] of patch-here = plat-num[
        stand person
      ]
  ]]
  [
    move-around-randomly person
  ]
end

to move-along-corridor [person]
  ifelse [number] of patch-here = objective-number and [patch-type] of patch-here = "stairs"[ ; if we have arrived at the correct stairs
    ask person [
     set heading 0
      move-forward 2 myself
    ]
  ][  ; else of the if
  ask person [
    let num objective-number
    let x [pxcor] of one-of patches with [patch-type = "platform" and number = num ] ; pixel of the platform we want to get to
    ifelse x > xcor [  ; face and go right
       set heading 90
       move-forward 1 myself
    ][ ; face and go left (this is the else part of the if)

      set heading -90
        move-forward 1 myself
    ]
  ]]
end

to move-around-randomly [person] ; temp funciton where we just wiggle around a bit
  let n objective-number
  carefully [
  if ticks mod 5 = 0 [
    set heading towards one-of patches with [patch-type = "platform" and number = n] ]

  if [patch-type] of patch-ahead 1 != "line" [
    move-forward 1 myself
  ]][
   back 1
  ]

end

to stroll [person] ; temp funciton where we just wiggle around a bit
  let n objective-number
  carefully [
  if [patch-type] of patch-ahead 1 != "line" [
    move-forward 1 myself
  ]][
   move-forward -2 person
  ]


end


to board-train [person]
  let line objective-number  ; the line we want to join
  let nearest min-one-of trains with [train-line-number = line] [distance myself] ; closest carriage to me
    facexy  xcor  [pycor] of nearest ; face the y cordinate of the carriage
    if abs (ycor - [pycor] of nearest) <= 2[  ; we only look at the carriage if it is directly to the right/left of us
      face nearest
    ]

    move-forward 1 person
    if any? trains in-radius 2[  ; are we really close to the train?
    ask trains in-radius 2[  ; if yes, get on it and add to the count of the carriage
      set passenger-count passenger-count + 1
      set label passenger-count
      ]
     ask link-neighbors [
     die  ; remove the suitcase
    ]
     die ; this just removes the passenger from the game
]


end


to change-platform-step [person] ; lets try and change platform
  let p-num [number] of patch-here ; the number we are at
  let p-type [patch-type] of patch-here ; the type of patch we are on

  ifelse p-type = "platform"  [  ; if we are on a platform
    ifelse (p-num != objective-number) [  ; if this is the wrong platform
      ifelse p-num = 2 and objective-number = 3 or p-num = 3 and objective-number = 2 [ ; if we should be on 3 but are on 2 etc, we dont need to go to the stairs
        if (gait = "walking") [
          if ([breed] of person != securities) [try-and-find-a-place-to-sit person]
        ]
      ;  move-around-randomly person
        if ([breed] of person = passengers) [set objective "board-train"]
      ][ ; else we need to go to the stairs
    move-towards-the-stairs person
    ]][ ; else (i.e we are at the wrong objective number) we need to go to the stairs
      if (gait = "walking") [
        if ([breed] of person != securities) [try-and-find-a-place-to-sit person]
      ]
     ; move-around-randomly person
      if ([breed] of person = passengers) [set objective "board-train"]
    ]
  ][ ifelse p-type = "stairs" [ ; if we are on the stairs, lets move along the corridor
     move-along-corridor person
  ]
  [if p-type = "corridor" [ ; if we are on a corridor, keep going down it
     move-along-corridor person
]]]
end

to leaving_train_move
  ask trains with [leaving = true][
    forward 1
    if (ycor >= max-pycor or ycor <= max-pycor * 0.1)[
      ask link-neighbors[
       die
      ]
     die
    ]
  ]


end


to check_train_leave ; lets see if any trains need to leave
  ask trains with [arriving = false][  ; if they have arrived and the number of ticks is greater than the hold time, start to leave
    if ticks - stop-tick > train-hold-time [
      set leaving true
    ]
  ]
end


; passenger arrival function
to arrive [t]
 set arriving false
 set stop-tick ticks ; grab the tick count so we can know how long we've been here
 let coming-off random passenger-count ; a random number of passengers that we want to leave
 ask min-one-of (patches with [patch-type = "platform"]) [distance myself][ ; get patches near the train where the passengers can disambark to

  sprout-passengers coming-off [ ; create the passengers that leave the train
     set shape "person"
     set color blue
     set vulnerability (random-normal 0.5 0.125)
      if vulnerability > 1 [set vulnerability 1]
      if vulnerability < 0 [set vulnerability 0]
     set aesthetic (random-normal 0.5 0.125)
      if aesthetic > 1 [set aesthetic 1]
      if aesthetic < 0 [set aesthetic 0]
     set money ((aesthetic * random-normal 0 1 * 10) + (aesthetic * 50))
     set label-color black
     set gait "walking"
     set-objective self ; set objective function called to set where they want to go
     set has-baggage (random-float 1 > percentage_with_bag)
     set carrying-baggage has-baggage
     let noob self
     ask patch-here [
       link-baggage self noob
      ]
  ]


  ]
  set passenger-count passenger-count - coming-off ; adjust the counts
  set label passenger-count ; this label is the one shown on screen
end

; if we have added a carriage we need to update the carriage count on the train
to update-carriage-count [added line]
  if added[
  ask trains with [arriving  = true and train-line-number = line][
      set current-carriages current-carriages + 1
        ]
      ]

end


to add_carriages [line]
  let added false ; have we added an extra carriage in this tick
    ask trains with [arriving  = true and train-line-number = line][
    let head heading - 180 ; this is the direction behind us
   carefully [ ; this means we don't break if there are errors
      let patch-behind patch-at-heading-and-distance head 2 ; we create a new carriage 2 patches behind us
      if not added and current-carriages < max-carriages and not any? trains-on patch-behind and [patch-type] of patch-behind = "line" [
       hatch 1 [ ; create new carriage (that has the same attributes as the current one)
          set passenger-count random max_passengers_on_carriages_when_created; randomly assign the number of passengers
          set label passenger-count
          bk 2 ; move back two
        ]
      set added true ; we've added something
    ]][ print "no room"]

]

  update-carriage-count added line

end

; if the train is yet to find a good place to stop
to continue_arriving [line]

  ask trains with [arriving = true and train-line-number = line] [ ; ask all trains still arriving
   forward  1 ; move forward
   let p-ahead patch-ahead 10 ; here we check that the patch 10 places ahead isn't a corridor or empty, if it is STOP
    if p-ahead = nobody or [patch-type] of p-ahead = "corridor" [
      ask trains with [arriving = true and train-line-number = line][ ; ask all the carriages to stop (arrive)
        arrive myself
        ]
    ]
  ]

  add_carriages line ; add some carriages
end


; lets start the process of a train arriving
to train_arrive [line_number no_carriages] ; what line and how many carriages
    let start_x 0
    let start_y 0
    let head 0
    ifelse (line_number mod 2 = 0)[ ; do we start from the top or the bottom
      set start_x max [pxcor] of patches with [patch-type = "line" and number = line_number]
      set start_x start_x - 2
      set start_y max [pycor] of patches with [patch-type = "line" and number = line_number]
      set head 180

    ][
       set start_x min [pxcor] of patches with [patch-type = "line" and number = line_number]
       set start_y min [pycor] of patches with [patch-type = "line" and number = line_number]]
       set start_x start_x + 1
       ask patch start_x  start_y [ ; at the starting patch create a train
       sprout-trains 1 [
        set train-line-number  line_number
        set max-carriages no_carriages
        set current-carriages 0
        set passenger-count max_passengers_on_carriages_when_created
        set arriving true
        set leaving false
        set shape "truck"
        set heading head ; which way it starts facing
        set size 2
        set label passenger-count ; lets label the number of passengers on the carriage
      ]
         ]

end

; building the station entrance and exit
to build-entrance
  ; we want to build it in the center of the map (y-cords) on the far right and fari left
  ask patches with [(pxcor < 2 or pxcor > (max-pycor - 2)) and abs(pycor - max-pycor / 2) < 3][

        set pcolor black

        set patch-type "entrance"
        ifelse pxcor < 2[
      set number 1][set number 4]  ; what number platform is it on
  ]
end


to build_benches [x_cordinate]
  ask patches with [pxcor = round (x_cordinate) and patch-type = "platform"  and pycor < max-pycor - 5][

    carefully[
    if pycor mod 25 = 0[
      set pcolor bench-col
      ask patch-at 0 1 [
        set pcolor bench-col
      ]
      ask patch-at 0 2[
        set pcolor bench-col
      ]
    ]][print "oor"]

  ]

end


; building a platform and connecting stairs
to build-platform [patch-selected platform-number startx endx]
  ask patch-selected [
    if pxcor >= startx and pxcor <= endx [
      ifelse (pycor >= min-pycor + stairs-size) [

      set pcolor 4
      set number platform-number
      set patch-type "platform"
    ][
        set pcolor black

        set patch-type "stairs"
        set number platform-number
      ]
  ]]


end

; building the train line out of patches
to build-line [patch-selected line-number startx endx]
  ask patch-selected [
   if pxcor >= startx and pxcor <= endx [
     ifelse (pycor >= min-pycor + stairs-size) [
     set pcolor red
     set number line-number
     set patch-type "line"
    ] [

        set pcolor black

        set patch-type "corridor"
        set number line-number
      ]
  ]]
end

to build-bench-set
  build_benches (platform-size / 3)
  build_benches (platform-size  + track-size / 2) + platform-size
   build_benches (platform-size  + 3 * track-size / 2 ) + platform-size
  build_benches (3 * platform-size + 2 * track-size) + platform-size / 3
end


; build the train station out of the patches
to set-up-station
  ask patches [
    build-platform self 4 (max-pxcor - platform-size) max-pxcor ; self refers the the particular patch (pixel)

    build-platform self 1 0 platform-size
    build-platform self 2 (platform-size + 2 * track-size)  (platform-size + 3 * track-size)
    build-platform self 3 (platform-size + 3 * track-size) (platform-size + 4 * track-size)
    build-line self 1 platform-size (platform-size + track-size)
    build-line self 2 (platform-size + track-size) (platform-size + 2 * track-size)
    build-line self 3 (2 * platform-size + 2 * track-size) (2 * platform-size + 3 * track-size)
    build-line self 4 (2 * platform-size + 3 * track-size) (2 * platform-size + 4 * track-size)
  ]
  build-entrance
  build-bench-set

  build-cameras
end

to create-camera [field dist x y head]
  create-cameras 1 [ set ycor y set xcor x set heading head set fov field set dis dist]
end

to add-cameras
  create-camera   65 1.5 * platform-size 0 max-pycor 145
  create-camera   65 1.5 * platform-size 0 stairs-size 35
  create-camera   65 1.5 * platform-size max-pxcor stairs-size 325
  create-camera   65 1.5 * platform-size max-pxcor max-pycor 215
end

to build-cameras
  add-cameras
   ask cameras[
    let d dis
    let f fov
   ask patches in-cone d f [
      let col pcolor
      let v [visibility] of patches
      if v != true[
       set pcolor pcolor + 2
       set visibility true
    ]
  ]
  ]

end

; this is called when we are near the entrance and want to leave
to try-and-exit [person p-num]
     ifelse any? patches with [patch-type = "entrance"] in-radius 2[
       ask link-neighbors [
     die ; remove suitcases

    ]
       die  ; if we are within 2 pixels of the entrance - leave (die)
      ][ ; else we face the nearest entrance (we are already at the right platform at this point) and move towards it
        face min-one-of patches with [patch-type = "entrance" and number = p-num] [distance myself]
        move-forward 1 self]
end


; adds new passengers from the entrances
to add-new-passengers
  if (ticks mod ticks-per-arrival = 0)[ ; we do this every 'ticks per arrival' ticks
    let no-entering (random average-arrival-number) + 1 ; randomly choose the number to enter
    ask n-of no-entering patches with [patch-type = "entrance"][  ; ask n of the patches that are entrance to create a passenger
     sprout-passengers 1 [
     set shape "person"
     set color white
     set vulnerability (random-normal 0.5 0.125)
      if vulnerability > 1 [set vulnerability 1]
      if vulnerability < 0 [set vulnerability 0]
     set aesthetic (random-normal 0.5 0.125)
      if aesthetic > 1 [set aesthetic 1]
      if aesthetic < 0 [set aesthetic 0]
     set money ((aesthetic * random-normal 0 1 * 10) + (aesthetic * 50))
     set gait "walking"
     set objective-number (random 4) + 1 ; a random platform they want to get on
     set label-color black
     set has-baggage (random-float 1 < percentage_with_bag)
     set carrying-baggage has-baggage

     set wants-to-exit false ; if they have just entered they probably don't want to leave again
    ]
    link-baggage self one-of passengers-here
    ]
  ]
end



to follow-target
  ask criminals [
    let p-type [patch-type] of patch-here ; check the current patch type
    let p-num [number] of patch-here ;check the current patch number
    set victim-target passenger who-to-steal ;set golbal varialbe victim-target to who-to-steal input
    let p-num-victim [[number]of patch-here] of victim-target ; chekc the current patch number of the victim-target
    set objective-number p-num-victim ; set cirminal's objective-number to the vitim's current location
    face victim-target ; set direction towards the target victim

    ifelse p-num != objective-number or p-type != "platform" [  ; if criminal is on the wrong platform
      ifelse p-num = 2 and objective-number = 3 or p-num = 3 and objective-number = 2 [ ; if we should be on 3 but are on 2 etc, we dont need to go to the stairs
        fd 1] ; forward 1
      [change-platform-step myself]] ; change platform with objective-number as the vitim's current location
    [fd 1] ;forward 1 towards the viticm if criminal is on the same platform as the victim
  ]
end

to steal-target
   let temp1 [money] of criminals ; set local variable temp1 to hold criminal's initial balance
   let temp2 [money] of victim-target; set local varialbe temp2 to hold victim's initial balance
   let success-rate [vulnerability] of victim-target ; set local variable success-reate equal to global vulnerability of the victim
   ifelse random-float 1 < success-rate [ ; generate random floating number betwwen 0 and 1, if the number is less than the success-rate
    ask criminals [set money temp1 + temp2 ; ask criminal to set money of temp1 + temp2
      move-around-randomly myself] ;and start wondering around randomly
    ask victim-target[set money 0]]; ask vitim to set money to 0
  [ask criminals [move-around-randomly myself]] ;if fail to steal, move around randomly
end



to go ; the main function called with each tick
  ask passengers[
    let p-type [patch-type] of patch-here
    let p-num [number] of patch-here
    let v [visibility] of patch-here
    ifelse v = true[
      set visible true
      set seen true
    ][set visible false]
    if seen != true [set seen false]
    ifelse p-num != objective-number or p-type != "platform" [ ; if we are not at the right platform or not on a platform
       ifelse p-type = "entrance" and not wants-to-exit[ ; if we are on the entrance but don't want to leave
        move-around-randomly self
      ]
      [
       change-platform-step self  ; else we change to the correct platform
    ]][
      let line objective-number ; where we want to go
      ifelse any? trains with [train-line-number = line and arriving = false and leaving = false][ ; if there is a train will let people on it
        board-train self ; get on it
      ][
        if gait = "walking" [
          try-and-find-a-place-to-sit self
        ]

          ; move-around-randomly self
      ]]

    if wants-to-exit and p-num = objective-number and p-type != "corridor"[ ; if we want to exit and are on at the right exit
      try-and-exit self p-num

    ]


    ifelse show-target-value?
    [ set label round (aesthetic + vulnerability) ]
    [ set label "" ]

    ]



  ask securities[

    look self

    ifelse actioning = true[
      ;go-to self max-pycor - 3 max-pxcor - 4
      go-to self 3 4
    ][

    let p-type [patch-type] of patch-here
    let p-num [number] of patch-here
    ifelse p-num != objective-number or p-type != "platform" [

      change-platform-step self
    ][
      ifelse(ycor > max-pycor - 3)[ifelse (objective-number = 4)[set objective-number 1][set objective-number (objective-number + 1)] ][stroll self]
    ]
    ]
  ]


  ask criminals [
    let p-type [patch-type] of patch-here
    let p-num [number] of patch-here
    look self
    let v [visibility] of patch-here
      ifelse v = true[
        set visible true
        set seen true
      ][set visible false]
    if seen != true [set seen false]

    carefully[
      follow-target
        steal-target]
   [move-around-randomly self]
  ]

    let arriving-lines  remove-duplicates [train-line-number] of trains with [arriving = true] ; gets a list of arriving trains
    foreach arriving-lines [ ? -> continue_arriving ? ] ; for all of these arriving trains - keep trying to arrive
    check_train_leave ; check if any of the trains are due to leave
    leaving_train_move ; keep leaving trains leaving
    add-new-passengers ; maybe add some new passengers

  train-arrivals-check
  tick-advance 1 ; move time forward
end

to train-arrivals-check
  if ticks mod train_1_arrival_tick = 0 [
    train_arrive 1 number_of_carriages_train_1
  ]
  if ticks mod train_2_arrival_tick = 0 [
    train_arrive 2 number_of_carriages_train_2
  ]
    if ticks mod train_3_arrival_tick = 0 [
    train_arrive 3 number_of_carriages_train_3
  ]
    if ticks mod train_4_arrival_tick = 0 [
    train_arrive 4 number_of_carriages_train_4
  ]

end



; initialises the global variabels
to set-up-globals
  set platform-size (max-pxcor * 0.2)
  set track-size (max-pxcor * 0.1)
  set stairs-size max-pycor * 0.1
  set bench-col green
end

; creates an objective for a passenger leaving a train (arriving in the station)
to set-objective [person]


  if [breed] of person = passengers[


  let rand random-float 1
     ifelse rand < 0.2[  ; if the random number is less than 2 then they are wanting to leave
      set color pink ; just to see them
      set wants-to-exit true
      ifelse rand < 0.1[   ; do they want to leave from platform 1 or 4
          set objective-number 1][set objective-number 4]
      ][ ; else we set a platform number for them to aim for
       set wants-to-exit false
        set objective-number (random 4) + 1
      ]

  ]
  if [breed] of person = securities[set objective-number (random 4) + 1]

end

to link-baggage [patch_i person]

   if [has-baggage] of person [
    sprout-baggages 1[
      set owner person
      set shape "suitcase"
      create-link-with person
  ]]
end

; creates the initial pool of passengers
to init-people [number-to-place]
  ask n-of number-to-place (patches with [patch-type = "platform"])[ ; put them on a platform
    sprout-passengers 1 [
     set shape "person"
     set color white
     set vulnerability (random-normal 0.5 0.125)
      if vulnerability > 1 [set vulnerability 1]
      if vulnerability < 0 [set vulnerability 0]
     set aesthetic (random-normal 0.5 0.125)
      if aesthetic > 1 [set aesthetic 1]
      if aesthetic < 0 [set aesthetic 0]
     set money ((aesthetic * random-normal 0 1 * 10) + (aesthetic * 50))
     set label-color black
     set gait "walking"
     set has-baggage (random-float 1 > percentage_with_bag)
     set carrying-baggage has-baggage
     set-objective self ; set their objective

    ]
    link-baggage self one-of passengers-here
    ]
end

to init-security [number-to-place]
  ask n-of number-to-place (patches with [patch-type = "platform"])[ ; put them on a platform
    sprout-securities 1 [
     set shape "person"
     set color yellow
     set-objective self
     set gait "walking"
     set has-baggage False
     set carrying-baggage False
     set seen-list []
     set judgement (random-normal 0.5 0.125)
      if judgement > 1 [set judgement 1]
      if judgement < 0 [set judgement 0]
     ;set actioning true
    ]
    ]
end

;Starter -> give each person memory count (like 'counter' for each turtle with 'look' method), set value at memory-count%50 position of array

to look [person]

  let jointset (turtle-set securities criminals passengers)
  set jointset jointset with [self != myself]  ; remove self from agentset


  ask person[
   let my-list seen-list
   let pass-list []

   ask jointset in-cone 25 60[

      foreach my-list [[val]->
       set pass-list lput item 0 val pass-list
      ]

      let angle-list [0 0 0 0]

      ifelse member? self pass-list[

        let pos position self pass-list
        let properties item pos my-list
        set my-list remove-item pos my-list
        set pass-list remove-item pos pass-list
        set angle-list item 4 properties
        let angle get-angle myself self
          ifelse angle > 0 and angle < 90      [ set angle-list replace-item 0 angle-list 1 ]
          [ ifelse angle > 90 and angle < 180  [ set angle-list replace-item 1 angle-list 1 ]
          [ ifelse angle > 180 and angle < 270 [ set angle-list replace-item 2 angle-list 1 ]
                                               [ set angle-list replace-item 3 angle-list 1 ]
          ]]

        ;let vuln vulnerability
        ;let judegement [judgement] of myself
        ;let familiarity ((sum angle-list) + 1) * judgement
        ;set vuln vuln * familiarity
        set my-list lput (list self ticks xcor ycor angle-list vulnerability) my-list

        ][
        ifelse length my-list < 50[
          let angle get-angle myself self
          ifelse angle > 0 and angle < 90      [ set angle-list replace-item 0 angle-list 1 ]
          [ ifelse angle > 90 and angle < 180  [ set angle-list replace-item 1 angle-list 1 ]
          [ ifelse angle > 180 and angle < 270 [ set angle-list replace-item 2 angle-list 1 ]
                                               [ set angle-list replace-item 3 angle-list 1 ]
          ]]
          set my-list lput (list self ticks xcor ycor angle-list vulnerability) my-list
          let pos position self my-list
        ][
          set my-list but-first my-list
          set my-list lput (list self ticks xcor ycor angle-list vulnerability) my-list
          let angle get-angle myself self
          ifelse angle > 0 and angle < 90      [ set angle-list replace-item 0 angle-list 1 ]
          [ ifelse angle > 90 and angle < 180  [ set angle-list replace-item 1 angle-list 1 ]
          [ ifelse angle > 180 and angle < 270 [ set angle-list replace-item 2 angle-list 1 ]
                                               [ set angle-list replace-item 3 angle-list 1 ]
          ]]
          set my-list lput (list self ticks xcor ycor angle-list) my-list
        ]
      ]

  ]
  set seen-list my-list
  print seen-list
  ]

end


to-report get-angle [person target]
let dif 0
ask person[

    if [distance person] of target > 1[

    let heading-angle heading
    let perspective-angle heading

    ask target[
      set heading-angle heading
      set perspective-angle towards myself
    ]

    set dif heading-angle - perspective-angle
    if dif < 0 [set dif 360 + dif]
    ]
  ]
  report dif
end



to go-to [person x y]

  let target patch x y

  ask person [

    let person-p-type [patch-type] of patch-here
    let person-p-num [number] of patch-here
    let target-p-type [patch-type] of target
    let target-p-num [number] of target

    set objective-number target-p-num ; set objective-number equal to the target
    face target ; set direction towards the target

    ifelse distance target > 1 [ ;if distance between the criminal and the target victim is more than 1

      ifelse person-p-num != objective-number or person-p-type != target-p-type[

        ifelse person-p-num != objective-number[
          change-platform-step self][
          move-towards-the-stairs self
        ]
      ][
        forward 1
    ]] ; go to the platform that target is on
        [stop]
    ; move one step forwards towards the victim
  ]

end


to init-criminals
  ask n-of number-of-criminals (patches with [patch-type = "platform"])[
    sprout-criminals number-of-criminals [
    set shape "person"
    set color green
    set money 0
    set gait "walking"
    set has-baggage False
    set carrying-baggage False
    set seen-list []
    ]
  ]
end

to set-up

  clear-all ; resets the pixels
  RESET-TICKS ; resets time
  tick-advance 1
  set-up-globals ; sets up the global variables
  set-up-station ; create the station layout
  init-people 10 ; create the initial passengers in the station

  init-security 1

  init-criminals
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
978
779
-1
-1
10.0
1
10
1
1
1
0
0
0
1
0
75
0
75
0
0
1
ticks
30.0

BUTTON
138
70
211
103
set-up
set-up
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
127
105
190
138
NIL
go\n\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
15
204
115
264
train-hold-time
30.0
1
0
Number

MONITOR
1160
412
1303
457
Passengers @ station
count passengers
17
1
11

INPUTBOX
992
350
1141
410
ticks-per-arrival
2000.0
1
0
Number

INPUTBOX
1159
348
1308
408
average-arrival-number
0.0
1
0
Number

INPUTBOX
13
273
118
333
who-to-steal
4.0
1
0
Number

SWITCH
991
413
1150
446
show-target-value?
show-target-value?
1
1
-1000

INPUTBOX
991
449
1107
509
number-of-criminals
0.0
1
0
Number

INPUTBOX
994
285
1223
345
max_passengers_on_carriages_when_created
10.0
1
0
Number

INPUTBOX
1164
12
1313
72
train_1_arrival_tick
150.0
1
0
Number

INPUTBOX
1163
81
1312
141
train_2_arrival_tick
180.0
1
0
Number

INPUTBOX
1163
148
1312
208
train_3_arrival_tick
175.0
1
0
Number

INPUTBOX
1163
216
1312
276
train_4_arrival_tick
160.0
1
0
Number

INPUTBOX
997
12
1158
72
number_of_carriages_train_1
10.0
1
0
Number

INPUTBOX
996
85
1158
145
number_of_carriages_train_2
8.0
1
0
Number

INPUTBOX
996
152
1157
212
number_of_carriages_train_3
12.0
1
0
Number

INPUTBOX
996
218
1157
278
number_of_carriages_train_4
15.0
1
0
Number

INPUTBOX
991
511
1140
571
percentage_with_bag
0.2
1
0
Number

INPUTBOX
989
572
1138
632
chance-of-putting-down-bag
1.0
1
0
Number

INPUTBOX
1158
460
1307
520
chance-of-forget-bag
0.001
1
0
Number

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

suitcase
true
0
Rectangle -7500403 false true 60 120 240 240
Rectangle -7500403 true true 60 120 240 240
Rectangle -7500403 false true 105 90 120 120
Rectangle -7500403 true true 180 90 195 120
Rectangle -7500403 true true 105 75 195 90
Rectangle -7500403 true true 105 90 120 120

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
NetLogo 6.1.1
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
