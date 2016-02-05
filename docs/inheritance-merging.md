---
title: "Inheritance and Merging"
category: "dsl"
weight: 8
anchors:
  - title: "Template Inheritance"
    url: "#template-inheritance"
  - title: "Template Merging"
    url: "#template-merging"
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