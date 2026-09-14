namespace PooFlowProof.PooC3.NativeProjectionPipeline

universe u v w x

def compose (right : β → γ) (left : α → β) : α → γ :=
  fun value => right (left value)

theorem compose_associative
    (third : γ → δ)
    (second : β → γ)
    (first : α → β) :
    compose third (compose second first) =
      compose (compose third second) first := by
  funext value
  rfl

structure Projection (Key Value : Type u) where
  project : Key → Value

structure SoundCache
    {Key Value : Type u}
    (projection : Projection Key Value) where
  lookup : Key → Option Value
  agrees : ∀ key value, lookup key = some value → value = projection.project key

def cachedProject
    {Key Value : Type u}
    (projection : Projection Key Value)
    (cache : SoundCache projection)
    (key : Key) : Value :=
  match cache.lookup key with
  | some value => value
  | none => projection.project key

theorem sound_cache_preserves_projection
    {Key Value : Type u}
    (projection : Projection Key Value)
    (cache : SoundCache projection)
    (key : Key) :
    cachedProject projection cache key = projection.project key := by
  unfold cachedProject
  split
  next value evidence => exact cache.agrees key value evidence
  next => rfl

structure JsonStringPipeline
    (Domain Json StringValue : Type u) where
  jsonFrom : Domain → Json
  fromJson : Json → Domain
  stringFromJson : Json → StringValue
  jsonFromString : StringValue → Json
  jsonRoundTrip : ∀ value, fromJson (jsonFrom value) = value
  stringRoundTrip : ∀ json, jsonFromString (stringFromJson json) = json

def stringFrom
    {Domain Json StringValue : Type u}
    (pipeline : JsonStringPipeline Domain Json StringValue) :
    Domain → StringValue :=
  compose pipeline.stringFromJson pipeline.jsonFrom

def fromString
    {Domain Json StringValue : Type u}
    (pipeline : JsonStringPipeline Domain Json StringValue) :
    StringValue → Domain :=
  compose pipeline.fromJson pipeline.jsonFromString

theorem composed_string_round_trip
    {Domain Json StringValue : Type u}
    (pipeline : JsonStringPipeline Domain Json StringValue)
    (value : Domain) :
    fromString pipeline (stringFrom pipeline value) = value := by
  unfold fromString stringFrom compose
  rw [pipeline.stringRoundTrip]
  exact pipeline.jsonRoundTrip value

end PooFlowProof.PooC3.NativeProjectionPipeline
