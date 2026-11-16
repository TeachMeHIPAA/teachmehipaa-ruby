# Conditional requests

The API tags some objects with an ETag, a version marker that changes
whenever the object does. Sending the ETag back makes a write safe against
someone else's change, and makes a read cheap when nothing changed.

Every object a method returns has `last_response.etag` when the API sent
one. Wherever a method takes an ETag, you can pass the String or the object
you read, and the client sends that object's ETag.

## Conditional writes: `if_match:`

`learners.update` and `webhook_subscriptions.update` require `if_match:`;
the API refuses an update without one. `learners.offboard` takes it
optionally. If the object changed since you read it, the write is refused
with `PreconditionFailedError` (412), so you never overwrite a change you
haven't seen:

<!-- sample: conditional-write -->
```ruby
learner = client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")
begin
  updated = client.learners.update(learner.learner_id, if_match: learner, name: "Ana Q. Example", external_id: nil)
  puts updated.name
rescue TeachMeHipaa::PreconditionFailedError
  puts "Someone else changed this Learner; read it again"
end
```

On a `PreconditionFailedError`, read the object again, reapply your change
to the fresh copy, and retry the update with its ETag. The client never does
that for you, since only you can tell whether your change still applies.

## Merge-patch updates

Updates are JSON merge patches, so they change only what you send:

- a keyword you leave out is not sent, and the field stays as it is;
- `nil` is sent as JSON `null`, and clears the field.

In the sample above, `name:` changes the name, `external_id: nil` clears the
External ID, and every other field is untouched. To forward a change only
when you have one, pass `TeachMeHipaa::OMIT`, which means "leave this field
unchanged", just as leaving the keyword out does:

<!-- sample: merge-patch -->
```ruby
changes = { name: "Ana Q. Example" } # from your HR system; no External ID change

learner = client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")
client.learners.update(
  learner.learner_id,
  if_match: learner,
  name: changes.fetch(:name, TeachMeHipaa::OMIT),
  external_id: changes.fetch(:external_id, TeachMeHipaa::OMIT),
)
puts "updated"
```

## Conditional reads: `if_none_match:`

`courses.retrieve`, `enrollments.retrieve` and
`webhook_subscriptions.retrieve` take `if_none_match:`. When your copy is
still current, the API answers 304 and the method returns
`TeachMeHipaa::NotModified` instead of the object. Everything a method
returns answers `not_modified?`, so keep your copy when it says true:

<!-- sample: not-modified -->
```ruby
course = client.courses.retrieve("hipaa-2026")

latest = client.courses.retrieve("hipaa-2026", if_none_match: course)
course = latest unless latest.not_modified?
puts course.title
```

This suits a cache: store the object, and refresh it with `if_none_match:`
instead of fetching it whole each time.
