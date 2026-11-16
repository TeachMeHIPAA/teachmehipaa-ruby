# Versioning

## The library's version

The library follows [semantic versioning](https://semver.org/):

- a **patch** release fixes bugs;
- a **minor** release adds methods, fields, parameters or Event types, and
  never breaks code written against an earlier minor release;
- a **major** release may break code, and the
  [changelog](../../CHANGELOG.md) says what to change.

<!-- sample: version -->
```ruby
puts TeachMeHipaa::VERSION
```

Until 1.0 the library is pre-release, and minor releases may still change
its interface. Pin a version (or, while installing from GitHub, a `ref:`)
and read the changelog before you upgrade.

## Which API it targets

The resources and models are generated from the Developer API's OpenAPI
document. `OPENAPI_VERSION`, at the root of this repository, names the
document release a version of the library was generated from, and each
changelog entry repeats it. The [resource
reference](../reference/resources.md) is generated from the same document.

## API changes that don't break you

The Developer API evolves by adding things: new fields, new optional
parameters, new error codes, new Event types and new enum values. The
library is built so that these additions never break code written against
an older version:

- **Unknown fields are kept.** A field this version doesn't know is still on
  the model; read it with `[]` by the API's name, and `to_h` includes it.
- **Enum values are open.** Enum fields are plain Strings, so a value newer
  than the library arrives as is. The generated constants
  (`TeachMeHipaa::LearnerStatus::COMPLIANT` and so on) name the values this
  version knows.
- **New Event types arrive typed generically.** An Event of a type this
  version doesn't know is a `TeachMeHipaa::UnknownEvent`, in webhooks and in
  the Event log alike.
- **New error codes keep their class.** The error class depends on the HTTP
  status, and `code` is an open String.

So write code that expects them: an `else` on every `case` over a status,
Event type or error code.

<!-- sample: open-enums -->
```ruby
learner = client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")

case learner.status
when TeachMeHipaa::LearnerStatus::COMPLIANT then puts "compliant"
when TeachMeHipaa::LearnerStatus::EXPIRING_SOON then puts "renew soon"
else puts "status #{learner.status}"
end
puts learner["someNewField"].inspect
```

Upgrading the library then brings typed readers, constants and Event classes
for what the API added, and nothing you wrote stops working.
