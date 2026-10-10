;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Source-derived Org Elements live behind the parser-owning Orgize package.
(import (only-in :orgize/languages/org/v1/rowan-event-parser parse-org-rowan-events)
        :orgize/languages/org/v1/modules/org-elements/source-interface)
(export parse-org-rowan-events (import: :orgize/languages/org/v1/modules/org-elements/source-interface))
