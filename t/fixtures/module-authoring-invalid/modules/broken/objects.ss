;;; Inert negative fixture: command-shaped domain slots are forbidden.
(import "types.ss")
(export BrokenObject)
(.def BrokenObject
  (.add-event (.o event: BrokenType)))
