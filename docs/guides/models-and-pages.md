# Models, pages and ETags

Every method returns a plain Ruby object: a model for one record, a page for
a list. Both are frozen, so you can pass them between threads or keep them
in a cache. The samples here assume a `client` built as in the
[README](../../README.md#usage).

## Calling methods

Ids that sit in the URL come first, as positional arguments. Everything else
is a keyword, spelled in snake_case, so the API's `externalId` becomes
`external_id:` and a Learner lookup for one Course reads
`client.learners.retrieve(learner_id, course_id: "hipaa-2026")`.

Enum keywords take a Symbol or a String (`status: :expired` or
`status: "expired"`). Every method ends with an optional `request_options:`
Hash for that one call; [Setting up a client](client.md#options-for-one-call)
lists its keys.

## Reading a model

A model has a reader per field, in snake_case. Nested objects are models too,
and a field the API left empty reads as `nil`, which `&.` handles:

<!-- sample: responses -->
```ruby
learner = client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")

puts learner.email
puts learner.course.title
puts learner.certificate&.expires_at || "not certified yet"
puts learner.last_response.request_id
puts learner.to_h[:status]
```

- `to_h` returns every field under Symbol keys, with nested models turned
  into Hashes.
- `[]` takes a snake_case Symbol or the API's own name. It also reads fields
  newer than this version of the gem: `learner["someNewField"]`.
- `last_response` holds the HTTP `status`, `headers`, `request_id` and `etag`
  of the response the model came from. Nested models have `nil` there.
- Two models are `==` when they have the same class and the same fields, so
  they work as Hash keys.

Enum fields are Strings. The generated modules name the values this version
knows, such as `TeachMeHipaa::LearnerStatus::COMPLIANT`, and a value the API
adds later still arrives as a String.

## Pages

A list method returns a `TeachMeHipaa::Page`. It includes `Enumerable`, and,
the way Stripe's list objects do, it enumerates its own `items` and nothing
more. `map`, `count`, `first` and friends never touch the network:

<!-- sample: one-page -->
```ruby
page = client.learners.list(limit: 2)
puts page.count, page.map(&:email).join(", ")

puts page.next_page.first.email if page.next_page?
```

`next_page?` tells you whether the API sent a cursor, and `next_page` fetches
the page after it. `limit:` sets the page size, from 1 to 100, with 20 as the
default. A page can hold fewer items than the limit and still have a next
page, so loop on `next_page?` and ignore the count.

### Every item, across pages

`auto_paging_each` yields every item on this page and the ones after it. It
fetches a page only when the loop reaches it, and a `break` stops the
fetching:

<!-- sample: every-item -->
```ruby
client.learners.list(limit: 100).auto_paging_each do |learner|
  puts learner.learner_id
end
```

Call it without a block and you get an `Enumerator`. Make it `lazy` and
chain the usual methods; the client fetches only the pages the chain needs:

<!-- sample: lazy -->
```ruby
certified = client.learners.list.auto_paging_each.lazy.select(&:certificate).first(10)
puts certified.map(&:email)
```

### A page at a time

`each_page` yields whole pages, which suits batch jobs and progress bars.
Each page carries its own `last_response`:

<!-- sample: each-page -->
```ruby
client.certificates.list(limit: 100).each_page do |page|
  puts "Page of #{page.items.length} (request #{page.last_response.request_id})"
end
```

The later pages repeat the first call's filters, `limit:` and request
options.

## ETags

Some records carry an ETag, a version marker that changes whenever the
record does. The model keeps it in `last_response.etag`. Wherever a method takes an ETag, you can hand it the
model you read and the client pulls the ETag out.

### Safe updates with `if_match:`

`learners.update` and `webhook_subscriptions.update` refuse to run without
`if_match:`, and `learners.offboard` takes one if you have it. If somebody
changed the record after you read it, the API answers 412 and the client
raises `PreconditionFailedError`:

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

The client never retries a 412 for you. Read the record again, decide whether
your change still makes sense, and send it with the new ETag.

### Changing only some fields

Updates go out as JSON merge patches. A keyword you leave out isn't sent and
the field keeps its value. A keyword set to `nil` goes out as JSON `null` and
clears the field: above, `external_id: nil` wipes the External ID.

When the change comes from data you don't control, pass
`TeachMeHipaa::OMIT` for "leave this alone". It behaves as if you had left
the keyword out, which keeps `Hash#fetch` defaults tidy:

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

### Cheap re-reads with `if_none_match:`

`courses.retrieve`, `enrollments.retrieve` and
`webhook_subscriptions.retrieve` take `if_none_match:`. When your copy is
current the API answers 304 and the method returns a
`TeachMeHipaa::NotModified`. Models and `NotModified` both answer
`not_modified?`, so a cache refresh fits on two lines:

<!-- sample: not-modified -->
```ruby
course = client.courses.retrieve("hipaa-2026")

latest = client.courses.retrieve("hipaa-2026", if_none_match: course)
course = latest unless latest.not_modified?
puts course.title
```
