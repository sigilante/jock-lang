/+  jock,
    test
::
|%
++  text
  'let a: @ = 3;\0a\0aif a == 3 {\0a  72\0a} else if a == 5 {\0a  17\0a} else {\0a  15\0a}\0a'
++  test-tokenize
  %+  expect-eq:test
    !>  ~[[%keyword %let] [%name %dec] [%punctuator %'='] [%punctuator %'('] [%name %a] [%punctuator %':'] [%punctuator %'@'] [%punctuator %'-'] [%punctuator %'>'] [%punctuator %'@'] [%punctuator %')'] [%punctuator %'{'] [%keyword %let] [%name %b] [%punctuator %'='] [%literal [%number 0]] [%punctuator %';'] [%keyword %loop] [%punctuator %';'] [%keyword %if] [%name %a] [%punctuator %'='] [%punctuator %'='] [%punctuator %'+'] [%punctuator %'('] [%name %b] [%punctuator %')'] [%punctuator %'{'] [%name %b] [%punctuator %'}'] [%keyword %else] [%punctuator %'{'] [%name %b] [%punctuator %'='] [%punctuator %'+'] [%punctuator %'('] [%name %b] [%punctuator %')'] [%punctuator %';'] [%keyword %recur] [%punctuator %'}'] [%punctuator %'}'] [%punctuator %';'] [%name %dec] [%punctuator %'('] [%literal [%number 5]] [%punctuator %')']]
    !>  (rash text parse-tokens:jock)
::
++  test-jeam
  %+  expect-eq:test
    !>  ^-  jock:jock
        [%let type=[p=[%untyped ~] name=%dec] val=[%lambda p=[arg=[inp=[~ [p=[%atom p=%number] name=%a]] out=[p=[%atom p=%number] name=%$]] body=[%let type=[p=[%untyped ~] name=%b] val=[%atom p=[%number 0]] next=[%loop next=[%if cond=[%compare a=[%limb p=~[[%name p=%a]]] comp=%'==' b=[%increment val=[%limb p=~[[%name p=%b]]]]] then=[%limb p=~[[%name p=%b]]] after=[%else then=[%edit limb=~[[%name p=%b]] val=[%increment val=[%limb p=~[[%name p=%b]]]] next=[%call func=[%limb p=~[[%axis p=0]]] arg=~]]]]]] payload=~]] next=[%call func=[%limb p=~[[%name p=%dec]]] arg=[~ [%atom p=[%number 5]]]]]
    !>  (jeam:jock text)
::
++  test-mint
  %+  expect-eq:test
    !>  [8 [8 [1 0] [1 8 [1 0] 8 [1 6 [5 [0 30] 4 0 6] [0 6] 7 [10 [6 4 0 6] 0 1] 9 2 0 1] 9 2 0 1] 0 1] 8 [0 2] 9 2 10 [6 7 [0 3] 1 5] 0 2]
    !>  (mint:jock text)
--
