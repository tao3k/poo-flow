#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Script entrypoint for the local poo-flow CLI wrapper.

(import :cli)

(poo-flow-cli-main (poo-flow-cli-script-args (command-line)))
