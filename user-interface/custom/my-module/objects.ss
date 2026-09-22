;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        "types.ss")
(export poo-flow-custom-my-module-metadata)

(def poo-flow-custom-my-module-metadata
  (.o identity: +poo-flow-custom-my-module-identity+
      owner: 'user
      public-entry: 'interface
      runtime-executed?: #f))
