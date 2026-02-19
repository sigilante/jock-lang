/+  jock
::
|_  [libs=(map term cord) dbg=?]
++  parse
  |=  =cord
  ^-  (list token:jock)
  ~|  %parse
  (rash cord parse-tokens:~(. jock [libs dbg]))
::
++  jeam
  |=  =cord
  ^-  jock:jock
  ~|  %jeam
  =/  res=(unit jock:jock)
    %-  mole
    |.
    (jeam:~(. jock [libs dbg]) cord)
  ?~  res
    *jock:jock
  u.res
::
++  mint
  |=  =cord
  ^-  nock:jock
  ~|  %mint
  =/  res=(unit *)
    %-  mole
    |.
    (mint:~(. jock [libs dbg]) cord)
  ?~  res
    *nock:jock
  ;;(nock:jock u.res)
::
++  jype
  |=  =cord
  ^-  jype:jock
  ~|  %jype
  =/  res=(unit jype:jock)
    %-  mole
    |.
    (jypist:~(. jock [libs dbg]) cord)
  ?~  res
    *jype:jock
  u.res
::
++  nock
  |=  =cord
  ^-  *
  ~|  %nock
  =/  nok  (mint:~(. jock [libs dbg]) cord)
  =/  res=(unit *)
    %-  mole
    |.
    .*(0 nok)
  ?~  res
    ~&  %nock-crashed
    0
  u.res
::
++  exec
  |=  =cord
  ^-  *
  =/  nok  (mint:~(. jock [libs dbg]) cord)
  .*(0 +.nok)
::
--
