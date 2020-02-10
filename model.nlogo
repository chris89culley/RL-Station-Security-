breed [securities security] ;This is how we define new breeds
breed [criminals criminal]
breed [passengers passenger]
breed [trains train]
globals [platform-size track-size stairs-size] ;global variables
passengers-own [objective objective-number wants-to-exit money vulnerability aesthetic] ; features that passengers can be given
patches-own [patch-type number] ; features each of the pixels (patches) can be given
trains-own [max-carriages leaving arriving train-line-number current-carriages stop-tick passenger-count]
criminals-own [ objective objective-number money wants-to-exit] ; features that criminals can be given


; sets the heading towards the nearest stair pixel and move towards it
to move-towards-the-stairs [person]
    ask person [
     let target-patch min-one-of (patches with [patch-type = "stairs"]) [distance myself] ;find the nearest stair pixel
     set heading towards  target-patch ; look at it
    forward 1] ; move to it
end



to move-along-corridor [person]
  ifelse [number] of patch-here = objective-number and [patch-type] of patch-here = "stairs"[ ; if we have arrived at the correct stairs
    ask person [
     set heading 0
     forward 2
    ]
  ][  ; else of the if
  ask person [
    let num objective-number
    let x [pxcor] of one-of patches with [patch-type = "platform" and number = num ] ; pixel of the platform we want to get to
    ifelse x > xcor [  ; face and go right
       set heading 90
       forward 1
    ][ ; face and go left (this is the else part of the if)

      set heading -90
      forward 1
    ]

  ]]

end

to move-around-randomly [person] ; temp funciton where we just wiggle around a bit
  let n objective-number
  carefully [
  if ticks mod 5 = 0 [
    set heading towards one-of patches with [patch-type = "platform" and number = n] ]

  if [patch-type] of patch-ahead 1 != "line" [
    forward 1
  ]][
   back 1
  ]


end


to board-train [person]
  let line objective-number  ; the line we want to join
  let nearest min-one-of trains with [train-line-number = line] [distance myself] ; closest carriage to me
    facexy  xcor  [pycor] of nearest ; face the y cordinate of the carriage
    if abs (ycor - [pycor] of nearest) <= 2[  ; we only look at the carriage if it is directly to the right/left of us
      face nearest
    ]

    forward 1
    if any? trains in-radius 2[  ; are we really close to the train?
    ask trains in-radius 2[  ; if yes, get on it and add to the count of the carriage
      set passenger-count passenger-count + 1
      set label passenger-count
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
        move-around-randomly person
        set objective "board-train"
      ][ ; else we need to go to the stairs
    move-towards-the-stairs person
    ]][ ; else (i.e we are at the wrong objective number) we need to go to the stairs

      move-around-randomly person
      set objective "board-train"
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
     set vulnerability (abs random-normal 15 8)
     set aesthetic (abs random-normal 30 10)
     set money (aesthetic + random-normal 25 5)
     set label-color black
     set-objective self ; set objective function called to set where they want to go
  ]]
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
  ]][ print "no room"]]

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
        set passenger-count (random 5)
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
        set pcolor orange
        set patch-type "entrance"
        ifelse pxcor < 2[
      set number 1][set number 4]  ; what number platform is it on
  ]
end


; building a platform and connecting stairs
to build-platform [patch-selected platform-number startx endx]
  ask patch-selected [
    if pxcor >= startx and pxcor <= endx [
      ifelse (pycor >= min-pycor + stairs-size) [
      set pcolor gray
      set number platform-number
      set patch-type "platform"
    ][
        set pcolor orange
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
        set pcolor orange
        set patch-type "corridor"
        set number line-number
      ]
  ]]
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
end

; this is called when we are near the entrance and want to leave
to try-and-exit [person p-num]
     ifelse any? patches with [patch-type = "entrance"] in-radius 2[
       die  ; if we are within 2 pixels of the entrance - leave (die)
      ][ ; else we face the nearest entrance (we are already at the right platform at this point) and move towards it
        face min-one-of patches with [patch-type = "entrance" and number = p-num] [distance myself]
        forward 1]
end


; adds new passengers from the entrances
to add-new-passengers
  if (ticks mod ticks-per-arrival = 0)[ ; we do this every 'ticks per arrival' ticks
    let no-entering (random average-arrival-number) + 1 ; randomly choose the number to enter
    ask n-of no-entering patches with [patch-type = "entrance"][  ; ask n of the patches that are entrance to create a passenger
     sprout-passengers 1 [
     set shape "person"
     set color white
     set objective-number (random 4) + 1 ; a random platform they want to get on
     set vulnerability ( abs random-normal 15 8 )
     set aesthetic (abs random-normal 30 10)
     set money (aesthetic + random-normal 25 5)
     set label-color black
     set wants-to-exit false ; if they have just entered they probably don't want to leave again
    ]]
  ]
end

to follow-target

  ask criminals [
    let p-type [patch-type] of patch-here
    let p-num [number] of patch-here
    set objective-number [objective-number] of passenger who-to-steal ; set objective-number equal to the target victim
    face passenger who-to-steal ; set direction towards the target victim
    ifelse distance passenger who-to-steal > 1 [ ;if distance between the criminal and the target victim is more than 1
      ifelse p-num != objective-number or p-type != "platform"  ; if criminal is on the wrong platform
        [ change-platform-step self ] ; go to the platform that the victim is heading
        [ move-around-randomly self]] ; move randomly if already on the correct platform
        [ fd 1 ] ; move one step forwards towards the victim
      if [pcolor] of patch-ahead 1 = red
      [ lt 180  ;; See a red patch ahead : turn left by 180 degree
       fd 1 ]                  ;; Otherwise, its safe to go foward.

  ]
end

to steal-target [ turtle1 turtle2 ]
  let temp [money] of turtle1 ; temp variable for consecutive pick-pocket development
  ask turtle1 [ set money [ money ] of turtle2 ] ; set money to the same value as the victim
  ask turtle2 [ set money 0] ; set victim's money value to zero
end



to go ; the main function called with each tick
  ask passengers[
    let p-type [patch-type] of patch-here
    let p-num [number] of patch-here
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
           move-around-randomly self
      ]]

    if wants-to-exit and p-num = objective-number and p-type != "corridor"[ ; if we want to exit and are on at the right exit
      try-and-exit self p-num
      ]
    ifelse show-target-value?
    [ set label round (aesthetic + vulnerability) ]
    [ set label "" ]

    ]

    let arriving-lines  remove-duplicates [train-line-number] of trains with [arriving = true] ; gets a list of arriving trains
    foreach arriving-lines [ ? -> continue_arriving ? ] ; for all of these arriving trains - keep trying to arrive
    check_train_leave ; check if any of the trains are due to leave
    leaving_train_move ; keep leaving trains leaving
    add-new-passengers ; maybe add some new passengers

  tick-advance 1 ; move time forward
end


  ask criminals [ follow-target
    if distance passenger who-to-steal < 1 [ steal-target criminals passenger who-to-steal]]



    let arriving-lines  remove-duplicates [train-line-number] of trains with [arriving = true] ; gets a list of arriving trains
    foreach arriving-lines [ ? -> continue_arriving ? ] ; for all of these arriving trains - keep trying to arrive
    check_train_leave ; check if any of the trains are due to leave
    leaving_train_move ; keep leaving trains leaving
    add-new-passengers ; maybe add some new passengers



  tick-advance 1 ; move time forward
end


; initialises the global variabels
to set-up-globals
  set platform-size (max-pxcor * 0.2)
  set track-size (max-pxcor * 0.1)
  set stairs-size max-pycor * 0.1
end

; creates an objective for a passenger leaving a train (arriving in the station)
to set-objective [person]
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

end

; creates the initial pool of passengers
to init-people [number-to-place]
  ask n-of number-to-place (patches with [patch-type = "platform"])[ ; put them on a platform
    sprout-passengers 1 [
     set shape "person"
     set color white
     set vulnerability ( abs random-normal 15 8 )
     set aesthetic (abs random-normal 30 10)
     set money (aesthetic + random-normal 25 5)
     set label-color black
     set-objective self ; set their objective
    ]
    ]
end

to init-criminals
  ask n-of number-of-criminals (patches with [patch-type = "platform"])[
    sprout-criminals number-of-criminals [
    set shape "person"
    set color green
    set money 0
    ]
   ]
end
to set-up

  clear-all ; resets the pixels
  RESET-TICKS ; resets time
  set-up-globals ; sets up the global variables
  set-up-station ; create the station layout
  init-people 10 ; create the initial passengers in the station
  init-criminals

end
