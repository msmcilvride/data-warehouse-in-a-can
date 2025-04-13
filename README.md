#
```
zip -r ../producer-source.zip .
```

# Todo
- Audience in main.tf
  - Remove?
  - Or built iy dynamically
- Flesh out dummy events
  - Multiple users
  - Multiple event types
  - Event type vs action?
  - Actual timestamp
- Write a custom Dataflow, or look for other templates
  - Is there a flex record that writes to JSON?
  - Write to JSON, not RECORD
  - Validation? What else can be done here that would be useful?
