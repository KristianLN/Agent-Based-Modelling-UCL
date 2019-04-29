extensions [matrix]

globals
[
  ;; Matrices
  row_payoff-matrix
  column_payoff-matrix
  FPpayoff-matrix

  ;; Operational
  num-turtles
  average-turtle-size
  pick1
  pick2
  picks
  ;pick3
  turtle1
  turtle2
  colors
  choice
  interactions
  irrationality

  ;; Fictitious play
  currentBeliefs
  holder
  updatedReward

  ;; Multi Agent Fictitious play
  localStrategy
  globalStrategy
  globalHolder1
  globalHolder2
  globalBeliefs
  globalUpdatedReward
  stickToStrategy

  ;; Parameters to monitor
  totalRandomUtility
  totalTFTUtility
  totalFPUtility
  totalMAFPUtility
  averageGlobalBeliefsFP
  averageGlobalBeliefsMAFP

  ;; Operational variables for monitoring
  holderFP
  averageLocalBeliefsFP
  holderMAFP
  averageLocalBeliefsMAFP
  intraGameActions
  mostPlayedAction
  latestMostPlayedAction
]

directed-link-breed [connections connection]

turtles-own
[
  my-strategy
  utility
  strategy
  rationality
  decision
]

links-own

[
  history
  beliefs
]

to setup

  ca

  setup-globals
  setup-turtles
  set-links
  set-sizes
  reset-ticks

end

to setup-globals
  ;; Define the number of turtles
  set num-turtles numberOfTurtles

  ;; Define interactions
  set interactions []

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     Defining each of the two matrices based on the modeller-input       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; First, the matrices needs to initialised
  set row_payoff-matrix matrix:from-row-list [[0 0 0] [0 0 0] [0 0 0]]
  set column_payoff-matrix matrix:from-row-list [[0 0 0] [0 0 0] [0 0 0]]

  ;; Defining each element for the payoff-matrix of the row player
  matrix:set row_payoff-matrix 0 0 R_M_1_1
  matrix:set row_payoff-matrix 0 1 R_M_1_2
  matrix:set row_payoff-matrix 0 2 R_M_1_3
  matrix:set row_payoff-matrix 1 0 R_M_2_1
  matrix:set row_payoff-matrix 1 1 R_M_2_2
  matrix:set row_payoff-matrix 1 2 R_M_2_3
  matrix:set row_payoff-matrix 2 0 R_M_3_1
  matrix:set row_payoff-matrix 2 1 R_M_3_2
  matrix:set row_payoff-matrix 2 2 R_M_3_3

  ;; Defining each element for the payoff-matrix of the column player
  matrix:set column_payoff-matrix 0 0 C_M_1_1
  matrix:set column_payoff-matrix 0 1 C_M_1_2
  matrix:set column_payoff-matrix 0 2 C_M_1_3
  matrix:set column_payoff-matrix 1 0 C_M_2_1
  matrix:set column_payoff-matrix 1 1 C_M_2_2
  matrix:set column_payoff-matrix 1 2 C_M_2_3
  matrix:set column_payoff-matrix 2 0 C_M_3_1
  matrix:set column_payoff-matrix 2 1 C_M_3_2
  matrix:set column_payoff-matrix 2 2 C_M_3_3

  ;; Define a list of colors for the turtles for attain
  set colors (list green blue red yellow)

  ;; Initialise monitors

  set totalRandomUtility 0
  set totalTFTUtility 0
  set totalFPUtility 0
  set totalMAFPUtility 0
  set averageGlobalBeliefsFP [0 0 0]
  set averageGlobalBeliefsMAFP [0 0 0]
  set mostPlayedAction []
  set latestMostPlayedAction 0

end

to setup-turtles

  set-default-shape turtles "circle"

  crt num-turtles
  [
    set utility 1
    set-strategy
    set rationality (Lower_bound_rationality + (random-float (Upper_bound_rationality - Lower_bound_rationality)))
    set decision (Lower_bound_decision + (random-float (Upper_bound_decision - Lower_bound_decision)))
    ; Setting color based on the strategy each turtle employs
    set color (item my-strategy colors)

    create-connections-to other turtles
  ]

  layout-circle turtles min (list (4 * max-pxcor / 5) (4 * max-pycor / 5))

end

to set-strategy

  ; Drawing a random number to detemine the strategy of the player
  set choice random-float 1

  ; Tit for Tat
  if (choice >= 0 ) and (choice <= Frac_tit_for_tat)
    [
      set my-strategy 0 ; For now, is the default behavior to play friendly initially when the players strategy is Tit-for-tat
      set strategy "Tit for tat"
    ]
  ; Fictitious Play
  if (choice > Frac_tit_for_tat) and (choice <= (Frac_tit_for_tat + Frac_Fictitious_Play))
    [
      set my-strategy 0 ; Irrelevant as the played strategy will be calculated in the first round anyway
      set strategy "Fictitious Play"
    ]

  ; Multi-Agent Fictitious Play
  if (choice > Frac_tit_for_tat + Frac_Fictitious_Play) and (choice <= (Frac_tit_for_tat + Frac_Fictitious_Play + Frac_MA_Fictitious_Play))
    [
      set my-strategy 0 ; Irrelevant as the played strategy will be calculated in the first round anyway
      set strategy "Multi Agent Fictitious Play"
    ]

  ; Random strategy
  if (choice > (Frac_tit_for_tat + Frac_Fictitious_Play + Frac_MA_Fictitious_Play))
    [
      set my-strategy random 3
      set strategy "Random"
    ]

end

to set-links

  ask connections
  [
    set history []
    set beliefs (list (max (list 1 random Bound_beliefs_1)) (max (list 1 random Bound_beliefs_2)) (max (list 1 random Bound_beliefs_3)))
  ]

end

to go

  tick

  interaction

  ;; If sized wished updated
  if SetSizeAccordingToUtility
  [set-sizes]

  ;; Initialise operational variables
  set holderFP []
  set averageLocalBeliefsFP [0 0 0]
  set holderMAFP []
  set averageLocalBeliefsMAFP [0 0 0]
  set intraGameActions []

  ;; Monitor the progress prior to the game taking place
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ask turtles
  [
    ;; Agents employing the Random strategy
    if strategy = "Random"
    [set totalRandomUtility (totalRandomUtility + utility)]

    ;; Agents employing the Tit for Tat strategy
    if strategy = "Tit for tat"
    [set totalTFTUtility (totalTFTUtility + utility)]

    ;; Agents employing the Fictitious Play strategy
    if strategy = "Fictitious Play"
    [
      ;; Add the utility of the particular agent
      set totalFPUtility (totalFPUtility + utility)
      ;; Extract all beliefs
      ask my-out-connections [set holderFP fput beliefs holderFP]
      ;; Add them up
      foreach holderFP
      [
        x -> set averageLocalBeliefsFP (map + averageLocalBeliefsFP x)
      ]
      ;; Calculate the average
      set averageLocalBeliefsFP (map [i -> i / length holderFP] averageLocalBeliefsFP)
      ;; Normalising
      set averageLocalBeliefsFP (map [i -> i / sum averageLocalBeliefsFP] averageLocalBeliefsFP)
      ;; Update the average global beliefs with the local
      set averageGlobalBeliefsFP averageLocalBeliefsFP;(map + averageLocalBeliefsFP averageGlobalBeliefsFP)
    ]

    ;; Agents employing the Multi Agent Fictitious Play strategy
    if strategy = "Multi Agent Fictitious Play"
    [
      ;; Add the utility of the particular agent
      set totalMAFPUtility (totalMAFPUtility + utility)
      ;; Extract all beliefs
      ask my-out-connections [set holderMAFP fput beliefs holderMAFP]
      ;; Add them up
      foreach holderMAFP
      [
        x -> set averageLocalBeliefsMAFP (map + averageLocalBeliefsMAFP x)
      ]
      ;; Calculate the average
      set averageLocalBeliefsMAFP (map [i -> i / length holderMAFP] averageLocalBeliefsMAFP)
      ;; Normalising
      set averageLocalBeliefsMAFP (map [i -> i / sum averageLocalBeliefsMAFP] averageLocalBeliefsMAFP)
      ;; Update the average global beliefs with the local
      set averageGlobalBeliefsMAFP averageLocalBeliefsMAFP;(map + averageLocalBeliefsMAFP averageGlobalBeliefsMAFP)
    ]

  ]

  ; At each tick, each turtle play the game against one of its links at random.
  ask turtles
  [
    ;; Let the turtle play

    LetsPlayTheGame

    ;; Update interactions
    set interactions fput turtle2 interactions

    ;;; If the rules of the game is such that only the row player receives payoff (Column payoff matrix all zeros)
    ifelse (sum map sum matrix:to-row-list column_payoff-matrix) = 0
    [
      set utility (utility + matrix:get row_payoff-matrix pick1 pick2)
    ]
    [ ; If both players receive a payoff, independently whether the payoff matrices are symmetric
      set utility (utility + matrix:get row_payoff-matrix pick1 pick2)
      ask turtle turtle2 [set utility (utility + matrix:get column_payoff-matrix pick2 pick1)]
    ]
  ]

  ;; Adding the most played action to list
  set mostPlayedAction lput (item 0 (modes intraGameActions)) mostPlayedAction
  set latestMostPlayedAction (item ((length mostPlayedAction) - 1) mostPlayedAction)

end

to-report tit-for-tat [player1 player2]

  ; if the two agents have played against each other before, a strategy based on their history is chosen.

  ifelse empty? ([history] of connection player1 player2)
  [
    ifelse randomInitialisation
    [
      report (random 3)
    ]
    [
      report TFTinitialStrategy
    ]
  ]
  [
    report (item 0 ([history] of connection player1 player2))
  ]

end

to-report fictitiousPlay [player1 player2]

  set updatedReward []
  set holder []

  set currentBeliefs ([beliefs] of connection player1 player2)
  set currentBeliefs (map [i -> i / sum ([beliefs] of connection player1 player2)] currentBeliefs)

  ;; We check if any of the beliefs are the same which they can't be, because otherwise will the first
  ;; instance always be chosen
  if length (remove-duplicates currentBeliefs) < 3
  [
    set currentBeliefs (map [i -> i + random-float 0.000001] currentBeliefs)
  ]

  foreach currentBeliefs
  [
    x -> ;; In "holder" is stored each column multiple with the associated belief
    set holder lput (map [i -> i * x] matrix:get-column row_payoff-matrix (position x currentBeliefs)) holder
  ]

  ;; Multiplies column by column
  set updatedReward (map + ((map + (item 0 holder) (item 1 holder))) (item 2 holder))

  ;; We check if any of the rewards are the same, which they can't be because otherwise will the first
  ;; instance always be chosen
  if length (remove-duplicates updatedReward) < 3
  [
    set updatedReward (map [i -> i + random-float 0.000001] updatedReward)
  ]
  ;; Finds the row that contains the largest reward, and plays that
  report position (max updatedReward) updatedReward

end

to-report MAFictitiousPlay [player1 player2]

  set globalHolder1 []
  set globalHolder2 []
  set globalBeliefs [0 0 0]
  set globalUpdatedReward []

  set stickToStrategy random-float 1

  ;; Getting the local strategy for player1 against player2
  set localStrategy fictitiousPlay player1 player2

  ;; Finding the global beliefs
  ask turtle player1
  [
    ask my-out-connections [set globalHolder1 fput beliefs globalHolder1]
  ]

  ;; Adding the beliefs together
  foreach globalHolder1
  [
    x -> set globalBeliefs (map + globalBeliefs x)
  ]

  ;; From Fictitious play - Performing Fictitious play on the global beliefs

  set globalBeliefs (map [i -> i / sum (globalBeliefs)] globalBeliefs)

  ;; We check if any of the beliefs are the same which they can't be, because otherwise will the first
  ;; instance always be chosen
  if length (remove-duplicates globalBeliefs) < 3
  [
    set globalBeliefs (map [i -> i + random-float 0.000001] globalBeliefs)
  ]

  foreach globalBeliefs
  [
    x -> ;; In "globalHolder2" is stored each column multiple with the associated belief
    set globalHolder2 lput (map [i -> i * x] matrix:get-column row_payoff-matrix (position x globalBeliefs)) globalHolder2
  ]

  ;; Multiplies column by column
  set globalUpdatedReward (map + ((map + (item 0 globalHolder2) (item 1 globalHolder2))) (item 2 globalHolder2))

  ;; We check if any of the rewards are the same, which they can't be because otherwise will the first
  ;; instance always be chosen
  if length (remove-duplicates globalUpdatedReward) < 3
  [
    set globalUpdatedReward (map [i -> i + random-float 0.000001] globalUpdatedReward)
  ]
  ;; Finds the row that contains the largest reward
  set globalStrategy position (max globalUpdatedReward) globalUpdatedReward

  ;; What strategy to play - the initial or the new?
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ifelse localStrategy != globalStrategy
  [ ;; If the local and global strategy deviates, then the agent have to decide what to do
    ;; either to stick to his initial strategy (local) or go with the new alternative
    ifelse decision >= stickToStrategy
    [ ;; If he is more confident in his initial decision, go with the localStrategy
      report localStrategy
    ]
    [ ; Else go with the new strategy
      report globalStrategy
    ]
  ]
  [ ;; If the initial and the new strategy are the same, play either of them - here the local.
    report localStrategy
  ]

end

to LetsPlayTheGame

  ask one-of my-out-connections
    [
      ; If both players receive a payoff, independently whether the payoff matrices are symmetric
      set turtle1 [who] of end1
      set turtle2 [who] of end2

      ; Setting the strategies
      ; Row player
      checkStrategy turtle1 turtle2
      set pick1 [my-strategy] of turtle turtle1
      ;if [strategy] of turtle turtle1 = "Tit for tat"
      ;[print [history] of connection turtle1 turtle2]
      ;type "Player " type turtle1 type " played " print pick1

      ; Column player
      checkStrategy turtle2 turtle1
      set pick2 [my-strategy] of turtle turtle2

      ;; Add the actions to in intra-played-actions-list

      set intraGameActions lput pick1 intraGameActions
      set intraGameActions lput pick2 intraGameActions

      ; What happens below is the same as if pick1/pick2 where switched around, remembering the action of the opponent.
      ; However, I think it is wise to keep it in same notation as above, where it is only one player
      ask connection turtle1 turtle2 [set history fput pick2 history]
      ask connection turtle2 turtle1 [set history fput pick1 history]
    ]

end

to checkStrategy [turtleWho opponent]

  ;; Drawing a number to determine if the agent acts irrational
  set irrationality random 1

  ;;;;;;;;;;;;;;;;;; Setting the strategies ;;;;;;;;;;;;;;;;;;;;;;;

  ;; If the players strategy is "Random"
  ifelse ([strategy] of turtle turtleWho) = "Random"
  [
    ;print "I play a random strategy"
    ask turtle turtleWho [set my-strategy random 3]
  ]
  [ ; else determine if the agent acts irrational, and deviate from his strategy
    ifelse irrationality > [rationality] of turtle turtleWho
    [; If the agent acts irrational
      ask turtle turtleWho [set my-strategy random 3]
    ]
    [; If the agent acts as expected
      ; ----------------------------------------------------
      ;; If the players strategy is "Tit for tat"
      if ([strategy] of turtle turtleWho) = "Tit for tat"
      [
        ;print "I play Tit for tat"
        ask turtle turtleWho
        [
          set my-strategy tit-for-tat turtleWho opponent
          set color (item my-strategy colors)
        ]
      ]
      ; ----------------------------------------------------
      ;; If the players strategy is "Fictitious Play"
      if ([strategy] of turtle turtleWho) = "Fictitious Play"
      [
        ask turtle turtleWho
        [
          set my-strategy fictitiousPlay turtleWho opponent
          set color (item my-strategy colors)
        ]

        ask connection turtleWho opponent [ ; The way things are organised, implies that the strategy of interest also is the
                                            ; position in the beliefs that needs to be updated
          set beliefs replace-item (([my-strategy] of turtle opponent)) beliefs ((item ([my-strategy] of turtle opponent) beliefs) + 1)
        ]
      ]
      ; ----------------------------------------------------
      ;; If the players strategy is "Multi-Agent Fictitious Play"
      if ([strategy] of turtle turtleWho) = "Multi Agent Fictitious Play"
      [
        ;print "I play Multi Agent Fictitious Play"
        ask turtle turtleWho
        [
          set my-strategy MAFictitiousPlay turtleWho opponent
          set color (item my-strategy colors)
        ]

        ask connection turtleWho opponent [ ; The way things are organised, implies that the strategy of interest also is the
                                            ; position in the beliefs that needs to be updated
          set beliefs replace-item (([my-strategy] of turtle opponent)) beliefs ((item ([my-strategy] of turtle opponent) beliefs) + 1)
        ]
      ]
    ]
  ]

end

to interaction

  ;ask turtles [print [history] of my-links]

end

to set-sizes

  ask turtles [set size utility]

end
@#$#@#$#@
GRAPHICS-WINDOW
315
10
752
448
-1
-1
13.0
1
10
1
1
1
0
0
0
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
491
484
557
517
NIL
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
491
523
558
556
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
3
58
175
91
Frac_tit_for_tat
Frac_tit_for_tat
0
1 - Frac_Fictitious_Play - Frac_MA_Fictitious_Play
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
885
17
1087
45
Define payoff matrix for row player
11
0.0
1

TEXTBOX
1095
19
1324
47
Define payoff matrix for column player
11
0.0
1

INPUTBOX
869
38
931
98
R_M_1_1
2.0
1
0
Number

INPUTBOX
938
38
1001
98
R_M_1_2
1.0
1
0
Number

INPUTBOX
1007
39
1072
99
R_M_1_3
0.0
1
0
Number

INPUTBOX
869
106
931
166
R_M_2_1
3.0
1
0
Number

INPUTBOX
938
106
1001
166
R_M_2_2
1.0
1
0
Number

INPUTBOX
1007
107
1073
167
R_M_2_3
0.3
1
0
Number

INPUTBOX
870
174
932
234
R_M_3_1
4.0
1
0
Number

INPUTBOX
939
175
1001
235
R_M_3_2
1.0
1
0
Number

INPUTBOX
1009
175
1073
235
R_M_3_3
0.6
1
0
Number

INPUTBOX
1089
40
1148
100
C_M_1_1
2.0
1
0
Number

INPUTBOX
1157
41
1216
101
C_M_1_2
1.0
1
0
Number

INPUTBOX
1225
41
1284
101
C_M_1_3
0.0
1
0
Number

INPUTBOX
1090
108
1149
168
C_M_2_1
3.0
1
0
Number

INPUTBOX
1157
109
1216
169
C_M_2_2
1.0
1
0
Number

INPUTBOX
1224
109
1285
169
C_M_2_3
0.3
1
0
Number

INPUTBOX
1090
177
1147
237
C_M_3_1
4.0
1
0
Number

INPUTBOX
1157
178
1217
238
C_M_3_2
1.0
1
0
Number

INPUTBOX
1224
179
1285
239
C_M_3_3
0.6
1
0
Number

SLIDER
3
93
175
126
Frac_Fictitious_Play
Frac_Fictitious_Play
0
1 - Frac_tit_for_tat - Frac_MA_Fictitious_Play
0.17
0.01
1
NIL
HORIZONTAL

SLIDER
3
128
189
161
Frac_MA_Fictitious_Play
Frac_MA_Fictitious_Play
0
1 - Frac_Fictitious_Play - Frac_tit_for_tat
0.17
0.01
1
NIL
HORIZONTAL

TEXTBOX
5
14
308
84
Set the proportions of the strategies played by the agents in the game. Set Tit-for-tat first, with the other two equal to zero, and then adjust them.
11
0.0
1

TEXTBOX
492
467
642
485
Control Panel
11
0.0
1

TEXTBOX
3
172
199
214
Set bounds for 'rationality' of the agents  | 0 < L,U < 1 ^ sum(L,U) = 1 |
11
0.0
1

INPUTBOX
3
204
132
264
Lower_bound_rationality
0.5
1
0
Number

INPUTBOX
136
204
264
264
Upper_bound_rationality
0.5
1
0
Number

TEXTBOX
3
382
164
438
Set bounds for 'decision' of Multi-agent Fictitious Play agents | 0 < L,U < 1 ^ sum(L,U) = 1 |
11
0.0
1

INPUTBOX
3
428
132
488
Lower_bound_decision
1.0
1
0
Number

INPUTBOX
137
428
262
488
Upper_bound_decision
1.0
1
0
Number

TEXTBOX
4
266
288
336
Set bounds for 'beliefs' of the agents | Any integer > 0, preferably within reasonable distance from each other, to get reasonable probabilities |
11
0.0
1

INPUTBOX
3
311
96
371
Bound_beliefs_1
6.0
1
0
Number

INPUTBOX
99
311
190
371
Bound_beliefs_2
6.0
1
0
Number

PLOT
945
243
1286
443
Interactions with the other agents
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 0 numberOfTurtles" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram interactions"

TEXTBOX
576
467
726
485
Set the number of turtles
11
0.0
1

INPUTBOX
576
484
668
544
numberOfTurtles
10.0
1
0
Number

INPUTBOX
193
311
284
371
Bound_beliefs_3
6.0
1
0
Number

TEXTBOX
4
493
132
535
Initialisation of Tit-for-Tat | Either randomly or using a specified strategy |
11
0.0
1

SWITCH
3
536
166
569
randomInitialisation
randomInitialisation
1
1
-1000

INPUTBOX
3
573
158
633
TFTinitialStrategy
0.0
1
0
Number

SWITCH
320
484
487
517
SetSizeAccordingToUtility
SetSizeAccordingToUtility
1
1
-1000

PLOT
1287
40
1583
241
Total utility of "Random" agents
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
"default" 1.0 0 -16777216 true "" "plot totalRandomUtility"

PLOT
1289
244
1583
443
Total utility of "Tit for tat" agents
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
"default" 1.0 0 -16777216 true "" "plot totalTFTUtility"

PLOT
1586
40
1860
241
Total utility of "Fictitious Play" agents
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
"default" 1.0 0 -16777216 true "" "plot totalFPUtility"

PLOT
1586
244
1861
444
Total utility of "MA Fictitious Play" agents
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
"default" 1.0 0 -16777216 true "" "plot totalMAFPUtility"

PLOT
945
446
1286
643
Most played Action
NIL
NIL
0.0
3.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram mostPlayedAction"

@#$#@#$#@
The ODD Protocol

Word count (without headers and this line): 1045

	Purpose

The purpose of the model is to understand how the ability to learn affects the system dynamics in repeated stage games. The setup is a multi-agent repeated stage game, where agents decide how to act towards other agents. The sample space consists of three outcomes; Friendly, Neutral and Hostile. Each agent gets utility based on the attitude towards other agents, and the objective of agents is to maximise utility.

The setup implies system dynamics refers to aggregate utility and distribution of it, along with steady-state strategies and learning curves.

The research question of interest is; How does agent’s ability to learn affects the outcome of, potentially infinitely, repeated stages games? The prior motivates three sub-questions; How steep is the learning curve for agents and is the steepness affected by the number of agents? Steepness referrers to a potential burn-in period, in which agents learn the environment. Another question is, are the learning strategies, at any point doing the transition face to the steady-state strategy, if such exists, dominant to previously-known dominant strategies as Tit-for-tat?

A short note on notation: action referees to the actual move by an agent and strategy is the high-level plan the agent follows when choosing the action.  
	
	Entities, State variables and Scales

The entities in this model are agents, where the real-world interpretation could be nations, as an example. The state variables are utility, rationality, beliefs and experience, and the last three constitutes the level of utility of an agent. 

* Utility: Can attain any value from zero to infinity

* Rationality: Bounded between zero and one.

* Beliefs: Bounded between zero and one, a probability of playing each possible out.

* Experience: A list of previously actions by any agents in the space.

Each agent has a level of utility and a degree of rationality. Furthermore, each agent’s experience with – and beliefs about other agents, are represented as directed links to the other agents.
Time is discrete, and each step represents a new game between agents. There are as such no equality between time in the model and the real world, as there could be an arbitrary amount of real-world time between any two games.
Space does not have any implication or interpretation in the model.

	Process overview and Scheduling

[Flow Chart](https://www.dropbox.com/s/pnu6mko0819kx2k/Process.png?dl=0)
 
The scheduling in the model happens synchronously, as all agents play simultaneously. Within a stage game, actions of the players happen simultaneously, and all actions are observable.

	Design Concepts
		
* Basic Principles

The basic principles are standard game theory spiced with learning in repeated games.

In short, the NE of the stage game is the action in which none of the players benefits from deviating. The NE of the repeated game is not necessarily the same as the NE of the stage game, because temporal strategies arise.

The model considers three degrees of learning strategies; Tit-for-tat (TFT), fictitious play (FP) and an author-proposed extended version of FP, named multi-agent fictitious play (MA-FP). A process is needed for each of them. 

TFT: The agent plays the Nash Equilibrium (NE) by default. If the opponent deviates from the NE in period t, the agent deviates in period t+1 with the same response as the opponent did in period t.

FP: The agent assigns probabilities to the possible outcomes based on his experience with the opponent and plays the best response to his beliefs about what the opponent plays.

MA-FP: The agent evaluates the outcome of FP for the opponent and over the entire agent set (i.e. for an average agent). Deviations in the two beliefs, i.e. the best-response action, indicates some degree of irrationality in the opponent, and the agent can decide to act irrationally to counter the opponent’s irrationality. Decide is a probabilistic decision.

* Emergence

The following results seem reasonable to expect in advance.
	
	* TFT can be expected to dominate learning strategies for finite games, 	especially with short duration. Perhaps even after a potential burn-in period is disregarded, simply because it is a trigger strategy based on the best-response action.
	

* Learning-based strategies are expected to dominate for infinite repeated games, and the convergence to the steady-state strategy is expected to happen faster for MA-FP strategy, as it incorporates more information than the FP strategy.

* Too much irrationality could imply that TFT is dominant for infinite repeated games. With the reason being that learning is impossible because of the high level of stochasticity. 

* Adaption/Learning

The agents learn through their experience with other agents. All three strategies considered, utilise agents experience in some sense, with an increasing degree. 

* Stochasticity

Stochasticity is an important part of this model, as it is the factor that will drive the interesting insights of this model.

Stochasticity is essential for all strategies, and especially strategies based on FP. All agents have rationality, which is a percentage indicating how often they stick to the strategy and how often they deviate and employ a random action. 

For the FP-based strategies, further stochasticity is needed, namely for setting the initial beliefs. It is necessary because all agents otherwise will act the same, or at least within a very short time, depending on whether the payoff-matrix is symmetric or not. 

* Observation

The agent’s utility is measured and employed actions (beliefs). It enables us to measure the development in total utility, the distribution of the utility and how actions of the agents develop and potentially converge to steady-state strategies. More specific, the variables of interest are total utility for each strategy and average beliefs for the two learning-based strategies, implying six variables of interest.

A reasonable question is when the right time to observe is, and for this model, it is decided to observe the variables of interest, prior to a new round of stage games. 
The variables of interest will exhibit intra-round development, because agents can play against the same opponent within one round, and it could be interesting to consider the intra-round development. However, that is left for future investigation. 
	
	Initialisation

Initialising the world implies setting the initial level of utility, the level of rationality and the initial beliefs if needed.

* Parameters

The number of agents is by default ten, but is subject to change via the model-interface. The initial level of utility is by default one.
The stochastic parameters, initial beliefs, rationality and decision, are not the same for individual agents over simulations, but they are initialised with the same bounds.

* Strategies

The initialisation of Tit-for-tat can be done from the model-interface, with the default be playing zero (friendly). The initialisation can be stochastic or deterministic, depending on the setting of randomInitialisation and TFTinitialStrategy.

The initialisation of Fictitious Play and Multi-Agent Fictitious Play depends on the beliefs of the opponent, which is something to have in mind (Brown, 1951).

	Input data

No input data is used in this model as all data is generated inside the model.
	
	Sub-models

TFT:

a_(i,t)(a_(j,t-1) ) = {(a_NE if a_(j,t-1)=a_NE else a_(j,t-1)) for i,j=1,2,…,n and j≠i┤

FP:

A is the set of the opponent’s actions, and for every a∈A let w(a) be the number of times that the opponent has played action a. The agent assesses the opponent’s mixed strategy as

P(a) = w(a)/(∑_(a^'∈A)w(a^' ) )

MA-FP:

Following the above, define P_j (a) as the agent’s assessment of the opponents mixed strategy. Furthermore, define likewise P_e (a) as the agent’s assessment of the average agents mixed strategy.

a_(i,t)={(a if P_j (a) ≠ P_e(a) else a_(P(a))) for i,j=1,2,…,n and j≠i┤

	References:

Brown, G. W. (1951). Iterative solution of games by fictitious play. Activity analysis of production and allocation 13.1: 374-376.
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Simulation_1" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation 2" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_3" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_4" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_5" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_10" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_11" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_8" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_9" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_12" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_13" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_14" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_15" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_16" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_6" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Simulation_7" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>totalRandomUtility</metric>
    <metric>totalTFTUtility</metric>
    <metric>totalFPUtility</metric>
    <metric>totalMAFPUtility</metric>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <metric>latestMostPlayedAction</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="LearningCurve_1" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="LearningCurve_2" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="LearningCurve_3" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="LearningCurve_4" repetitions="500" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>averageGlobalBeliefsFP</metric>
    <metric>averageGlobalBeliefsMAFP</metric>
    <enumeratedValueSet variable="Frac_tit_for_tat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_2">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfTurtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_3">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_MA_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_1_3">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Frac_Fictitious_Play">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Bound_beliefs_1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_1">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_1_1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="C_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_2_3">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Upper_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_1">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TFTinitialStrategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R_M_3_3">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_decision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lower_bound_rationality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SetSizeAccordingToUtility">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomInitialisation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
