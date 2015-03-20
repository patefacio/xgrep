Needing to rethink filtering as it may be poorly specified. The idea
was to have a single filter allow for a set of inclusion constraints
and a set of exclusion constraints.

*Negative Filters*

The issue is the statement:

  I don't want to see *X* has potentially two meanings

When that is the only thing said it really means:

  I want to see everything but *X* which is *^X*

When it is used in conjunction with other statements it can mean:

  I don't really know what I want to see, but I don't want to see *X*.

*Positive Filters*

Similarly, an issue is the statement:

  I want to see *X* has potentially two meanings

When that is the only thing said it really means:

  I want to see only *X*

However, when it is used in conjunction with other statements it can mean:

  I don't know all that I want to see, but I at least want to see *X*


So, divide filters into inclusives and exclusives. If all filters are
inclusives the result is simply nothing, unless it appears in one of
the inclusives. Essentially it is, *only if*.

Similarly, if all filters are exclusives the result is simply
everything, unless it appears in one of the exclusives. Essentially it
is, *unless*.

Now, what if there are positive and negative filters specified? First
check the postive and if it is not present, exclude. If it is present,
check the excludes and if in the excludes, exclude it, otherwise leave
it. With this approach there is only real benefit if the inclusive
filters somehow overlap with the exclusive filters.

For instance, if there is:
  inclusives = .dart
  exclusives = .js

the exlusives has no effect because .js files would not be included
anyway. However, if it looks like this:

  inclusives = .dart, .html, .js, .yaml
  exclusives = .js

then the exclusives has an impact by refining the inclusives and
_unincluding_ some of them. So, this interaction can be useful with
predefined sets. Like I want all web files, which include js, but I
don't want js.

So the rule is:

If there are no inclusive filters, everything is included unless there
is an exclusive hit.

If there is even 1 inclusive filter, nothing is included unless there
is an inclusive hit and even then, only if there is not an exclusive hit.

Specifing filters is now easier. Each filter is a space delimited set
of patterns prefixed with either a '+' indicating inclusion or a '-'
indicating exclusion.

-f'id1 + \.dart$ \.html$ \.js'
-f'id2 - \.js$ \.ts$'

As before patterns are either plain strings or if they have characters
not in [\w_.] then regexes. If the pattern is a plain string the
filter decision is does the complete file path contain that text. The
benefit of this over the previous format is since it is either an
inclusion or an exclusion there is no need to split with '@'.




