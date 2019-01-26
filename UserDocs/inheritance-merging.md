---
title: "Inheritance and Merging"
category: "dsl"
weight: 8
anchors:
  - title: "Template Inheritance"
    url: "#template-inheritance"
  - title: "Template Merging"
    url: "#template-merging"
  - title: "Component and Dynamic Merging"
    url: "#component-and-dynamic-merging"
  - title: "Registry Items"
    url: "#registry-items"
---

## Inheritance and Merging

SparkleFormation includes functionality allowing SparklePacks to
interact with previous layers when a file is requested from the
collection. This functionality makes it easy to slightly modify
files provided within previously registered SparklePacks without
having to recreate the entire contents of the file. It also allows
for creation of new templates based on existing templates.

### Template Inheritance

Template inheritance allows a new template to inherit the data structures
of an existing template. For example, lets start with a simple template:

~~~ruby
SparkleFormation.new(:simple) do
  simple_template true
end
~~~

The dumped result of this template is:

~~~json
{
  "SimpleTemplate": true
}
~~~

Suppose that we wanted create a new template that was composed of everything
described in the `simple` template, but had an extra addition. Instead of
re-creating the contents in a new file, or attempting to break out components
or dynamics that may not be ideal, we can inherit the template instead:

~~~ruby
SparkleFormation.new(:advanced, :inherit => :simple) do
  advanced.item 'added'
end
~~~

When this template is dumped, it will inherit the `simple` template and
add on to the resultant data structure giving the result:

~~~json
{
  "SimpleTemplate": true,
  "Advanced": {
    "Item": "added"
  }
}
~~~

Inheritance is not restricted to templates at a common level. A new
template can inherit templates provided by SparklePacks.

### Template Merging

Template merging is only applicable when SparklePacks are in use. Template
merging allows direct modification of a specific named template. This strategy
is extremely useful when packs may be layering functionality into a template,
or the root pack wants to make a specific adjustment without creating a new
template.

The default behavior of SparkleFormation when a SparklePack provides a template with
the same name as a previously loaded SparklePack, it will overwrite the original
template. In some cases, this may not be the desired effect. If a pack would like
to make a simple adjustment to the template, this would require duplicating the
contents of the original template and appending the customization. Merging allows
adding customization without recreation.

Lets assume we have a core SparklePack loaded and it provides us with the `simple`
template:

~~~ruby
SparkleFormation.new(:simple) do
  simple_template true
end
~~~

Now in our root SparklePack we want to make an adjustment to the `simple` template
directly. We can do this by merging:

~~~ruby
SparkleFormation.new(:simple, :layering => :merge) do
  modifier 'spox'
end
~~~

When we dump the `simple` template now we get:

~~~json
{
  "SimpleTemplate": true,
  "Modifier": "spox"
}
~~~

This sort of merging make two strategies possible:

1. Modifying the final result of a template for a specific need
2. Modifying at serveral layers to allow SparklePacks to be additive

### Component and Dynamic Merging

Merging behavior for components and dynamics follows the same pattern as templates.
Adding the `:layering => :merge` option will cause the item to be merged instead
of overwritten.

For components:

~~~ruby
SparkleFormation.component(:name, :layering => :merge)
~~~

and dynamics:

~~~ruby
SparkleFormation.dynamic(:name, :layering => :merge)
~~~

#### Dynamic return value

The return value of a dynamic cannot be inferred. This is due to the freeform nature
of dynamics leaving the resulting return value up to the author of the dynamic. When
merging dynamics it can be easy to return the wrong value. The library _could_ take
care of this and always return the context provided by the initial dynamic, but this
behavior is problematic: merges could remove the original context, or may want to
change the return context completely. Returning the proper value is left to the
author, but SparkleFormation makes it easy to return the previous context.

When the dynamics are merged, SparkleFormation will include an extra key in the
options `Hash` for the dynamic: `:previous_layer_result`. Now a dynamic can merge
in extra changes, and ensure the correct value is returned from the call:

~~~ruby
SparkleFormation.dynamic(:name, :layering => :merge) do |name, args={}|
  new.things.added 'here'
  args[:previous_layer_result]
end
~~~

### Registry Items

Registry items are exempt from the merging behavior described above. Registry items
are always overwritten when redefined in higher level SparklePacks.
