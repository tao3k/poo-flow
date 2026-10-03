;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Public POO-native qualification interface; gerbil-parser owns grammar/CST.
(import "types.ss" "objects.ss" "funs.ss" "config.ss"
        "checked-source-types.ss" "checked-source-funs.ss"
        "emission-types.ss" "emission-funs.ss" "bundle-types.ss" "bundle-objects.ss" "bundle-funs.ss"
        "correspondence-types.ss" "correspondence-funs.ss")
(export (import: "bundle-types.ss" "bundle-objects.ss" "bundle-funs.ss")
        (import: "correspondence-types.ss" "correspondence-funs.ss")
        (import: "types.ss")
        (import: "objects.ss")
        (import: "funs.ss")
        (import: "config.ss")
        (import: "checked-source-types.ss")
        (import: "checked-source-funs.ss")
        (import: "emission-types.ss" "emission-funs.ss"))
