/+  jock,
    test-jock,
    *wrapper
=>
|%
+$  test-state  [%0 libs=(map term cord)]
++  moat  (keep test-state)
+$  cause
  $%  [%loadlibs libs=(list (pair term cord))]
      [%test n=@]
      [%test-all ~]
      [%exec n=@]
      [%exec-all ~]
      [%parseall ~]
      [%jeam-all ~]
      [%mint-all ~]
      [%jype-all ~]
      [%nock-all ~]
      [%run ~]
  ==
+$  effect  ~
--
%-  moat
^-  fort:moat
|_  k=test-state
::
::  +load: upgrade from previous state
::
++  load
  |=  arg=test-state
  ^-  test-state
  arg
::
::  +peek: external inspect
::
++  peek
  |=  =path
  ~
::
::  +poke: external apply
::
++  poke
  |=  input:moat
  ^-  [(list effect) test-state]
  ~&  "poked at {<now>}"
  =/  soft-cau  ((soft ^cause) cause)
  ?~  soft-cau  ~|("could not mold poke type: {<cause>}" !!)
  =/  c=^cause  u.soft-cau
  ?-    -.c
      %loadlibs
    =/  libs  `(map term cord)`(malt libs.c)
    ~&  >  "loading libs {<[~(key by libs)]>}"
    [~ k(libs libs)]
    ::
      %exec
    ~&  loaded-libs+[~(key by libs.k)]
    ?.  (gth (lent list-jocks:~(. test-jock [libs.k %.n])) n.c)
      ~&  >>>  "index out of range: {<n.c>}"
      [~ k]
    ~&  >  "running code {<n.c>}"
    =/  code  (snag n.c list-jocks:~(. test-jock [libs.k %.n]))
    ~&       code+[-:code]
    ~&  >    parse+(parse:~(. test-jock [libs.k %.n]) +.code)
    ~&  >>   jeam+(jeam:~(. test-jock [libs.k %.n]) +.code)
    =/  res  `*`(mint:~(. test-jock [libs.k %.n]) +.code)
    ~&  >    mint+res
    ~&  >>   jype+(jype:~(. test-jock [libs.k %.n]) +.code)
    ~&  >>>  nock+(nock:~(. test-jock [libs.k %.n]) +.code)
    [~ k]
  ::
      %exec-all
    ~&  exec-all:~(. test-jock [libs.k %.n])
    [~ k]
  ::
      %test
    ~&  "testing {<n.c>}"
    ~&  (test:~(. test-jock [libs.k %.n]) n.c)
    [~ k]
  ::
      %test-all
    ~&  test-all:~(. test-jock [libs.k %.n])
    [~ k]
  ::
      %parseall
    ~&  parse-all:~(. test-jock [libs.k %.n])
    [~ k]
  ::
      %jeam-all
    ~&  jeam-all:~(. test-jock [libs.k %.n])
    [~ k]
  ::
      %mint-all
    ~&  mint-all:~(. test-jock [libs.k %.n])
    [~ k]
  ::
      %jype-all
    ~&  jype-all:~(. test-jock [libs.k %.n])
    [~ k]
  ::
      %nock-all
    ~&  nock-all:~(. test-jock [libs.k %.n])
    [~ k]
  ::
      %run
    ~&  run-details:~(. test-jock [libs.k %.n])
    [~ k]
  ::
  ==
--
