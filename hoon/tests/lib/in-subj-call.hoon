/+  jock,
    test
::
|%
++  text
  'let a = 17;\0a\0alet b = ([b:@ c:&1] -> @) {\0a  if c == 18 {\0a    +(b)\0a  } else {\0a    b\0a  }\0a}([23 &1]);\0a\0a&1\0a\0a'
++  test-tokenize
  %+  expect-eq:test
    !>  ~[[%keyword %let] [%name %a] [%punctuator %'='] [%literal [%number 17]] [%punctuator %';'] [%keyword %let] [%name %b] [%punctuator %'='] [%punctuator %'('] [%punctuator %'['] [%name %b] [%punctuator %':'] [%punctuator %'@'] [%name %c] [%punctuator %':'] [%punctuator %'&'] [%literal [%number 1]] [%punctuator %']'] [%punctuator %'-'] [%punctuator %'>'] [%punctuator %'@'] [%punctuator %')'] [%punctuator %'{'] [%keyword %if] [%name %c] [%punctuator %'='] [%punctuator %'='] [%literal [%number 18]] [%punctuator %'{'] [%punctuator %'+'] [%punctuator %'('] [%name %b] [%punctuator %')'] [%punctuator %'}'] [%keyword %else] [%punctuator %'{'] [%name %b] [%punctuator %'}'] [%punctuator %'}'] [%punctuator %'('] [%punctuator %'['] [%literal [%number 23]] [%punctuator %'&'] [%literal [%number 1]] [%punctuator %']'] [%punctuator %')'] [%punctuator %';'] [%punctuator %'&'] [%literal [%number 1]]]
    !>  (rash text parse-tokens:jock)
::
++  test-jeam
  %+  expect-eq:test
    !>  ^-  jock:jock
        [%let type=[p=[%untyped ~] name=%a] val=[%atom p=[%number 17]] next=[%let type=[p=[%untyped ~] name=%b] val=[%call func=[%lambda p=[arg=[inp=[~ [[p=[p=[%atom p=%number] name=%b] q=[p=[%limb p=~[[%axis p=1]]] name=%c]] name=%$]] out=[p=[%atom p=%number] name=%$]] body=[%if cond=[%compare a=[%limb p=~[[%name p=%c]]] comp=%'==' b=[%atom p=[%number 18]]] then=[%increment val=[%limb p=~[[%name p=%b]]]] after=[%else then=[%limb p=~[[%name p=%b]]]]] payload=~]] arg=[~ [p=[%atom p=[%number 23]] q=[%limb p=~[[%axis p=1]]]]]] next=[%limb p=~[[%axis p=1]]]]]
    !>  (jeam:jock text)
::
++  test-mint
  %+  expect-eq:test
    !>  [8 [1 17] 8 [7 [8 [[1 0] [1 0] 1 0] [1 6 [5 [0 13] 1 18] [4 0 12] 0 12] 0 1] 9 2 10 [6 7 [0 3] [1 23] 0 1] 0 1] 0 1]
    !>  (mint:jock text)
--
