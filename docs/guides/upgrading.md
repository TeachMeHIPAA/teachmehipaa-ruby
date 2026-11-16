# Versions and upgrades

## What a version number promises

The gem follows [semantic versioning](https://semver.org/):

- a **patch** release fixes bugs;
- a **minor** release adds methods, fields, parameters or Event types, and
  code written for an earlier minor release keeps working;
- a **major** release may break code, and the [changelog](../../CHANGELOG.md)
  says what to change.

<!-- sample: version -->
```ruby
puts TeachMeHipaa::VERSION
```

Before 1.0 the gem is pre-release and a minor version can still change the
interface. While you install from GitHub, Bundler's `Gemfile.lock` holds the
commit, and `bundle update teachmehipaa` moves it. Read the changelog first.

## Ruby versions

The gemspec requires Ruby 3.2 or newer, and CI runs every push on 3.2, 3.3
and 3.4.

## Which API it speaks

The resources and models are generated from the Developer API's OpenAPI
document. `OPENAPI_VERSION`, at the root of the repository, names the
document release the code came from, and each changelog entry repeats it.
The [resource reference](../reference/resources.md) and the API reference's
Ruby samples come from the same release.

## Additions that won't break you

The API grows by adding things: fields, optional parameters, error codes,
Event types and enum values. The gem is built so that none of these breaks
code written against an older version:

- **Unknown fields stay on the model.** `[]` reads them by the API's name and
  `to_h` includes them.
- **Enums are open.** Enum fields are Strings, so a value newer than the gem
  comes through unchanged. The generated constants, such as
  `TeachMeHipaa::LearnerStatus::COMPLIANT`, name the values this version
  knows.
- **New Event types arrive as `TeachMeHipaa::UnknownEvent`,** in webhooks and
  in the Event log alike.
- **New error codes keep their class.** The class follows the HTTP status,
  and `code` is an open String.

Your half of the deal is an `else` on every `case` over a status, an Event
type or an error code:

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

After an upgrade, what the API added shows up as readers, constants and Event
classes, and the code you already wrote keeps running.
