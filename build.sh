#! /usr/bin/env bash

docker run \
  -v `pwd`/../minicron:/home/gusdev/minicron \
  -v `pwd`/../humming:/home/gusdev/humming \
  -v `pwd`:/home/gusdev/gh-hooks \
  -t -i images.reesd.com/reesd/stack \
  sh -c '
    cabal install minicron/minicron.cabal humming/humming.cabal --force-reinstalls ;
    cd gh-hooks ;
    ghc --make bin/gh-hooks.hs'
