#! /usr/bin/env bash

docker run \
  -v `pwd`:/home/gusdev/gh-hooks \
  -t -i images.reesd.com/reesd/stack \
  sh -c 'cd gh-hooks ; ghc --make bin/gh-hooks.hs'
