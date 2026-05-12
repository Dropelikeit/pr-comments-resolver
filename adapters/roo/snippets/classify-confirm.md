Display the proposed classification as two numbered lists. Use the comment numbers from the Step 3 unresolved-comments display so the user does not need to look up identifiers.

~~~
## Classification (proposed)

Deferred (<N>):
  <i>. <path>:<line>  — @<author> — "<short excerpt>"
       reason: <one short phrase, e.g. "security + new module needed">
  ...

Normal (<M>):
  <comma-separated indices>

Reply with one of:
  OK
  move <i>→normal
  move <i>→deferred
  exclude <i>
~~~

Emit the block as plain text and read free-form input. Re-render the block after each edit until the user replies `OK`.
