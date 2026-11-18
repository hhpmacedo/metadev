# Pattern catalogue

Common architecture patterns, when each fits and what each costs. Use it at step 4 of `solution-design` to name the options. It is a list of options, not a recommendation to use any of them.

## System structure

### Layered architecture

```
┌─────────────────────┐
│   Presentation      │  UI, CLI, API endpoints
├─────────────────────┤
│   Application       │  Business logic, workflows
├─────────────────────┤
│   Domain            │  Core entities, business rules
├─────────────────────┤
│   Infrastructure    │  Database, external services
└─────────────────────┘
```

- **When to use:** most applications. Clear separation, easy to understand.
- **Trade-off:** can lead to unnecessary abstraction in simple applications.

### Modular monolith

A single deployable unit with well-defined internal modules.

- **When to use:** starting a new project. It gives the benefits of modularity without the complexity of a distributed system.
- **Trade-off:** requires discipline to maintain module boundaries.

### Microservices

Independent services communicating over the network.

- **When to use:** large teams, independent scaling needs, different technology requirements per service.
- **Trade-off:** massive operational complexity. Do not use unless you have the problems it solves.

### Event-driven

Components communicate through events rather than direct calls.

- **When to use:** loose coupling is needed, operations are asynchronous, audit trails are important.
- **Trade-off:** flows are harder to trace; consistency is eventual.

## Data

### Repository pattern

Data access is abstracted behind an interface.

```
interface UserRepository {
  findById(id: string): User
  save(user: User): void
}
```

- **When to use:** when you might change data storage, or want to test business logic without a database.

### CQRS (Command Query Responsibility Segregation)

Separate read and write models.

- **When to use:** read and write patterns are very different, or querying needs are complex.
- **Trade-off:** significant complexity. Rarely needed.

### Event sourcing

Store events, not state. Derive current state from the event history.

- **When to use:** an audit trail is critical, past states must be reconstructed, the domain is complex.
- **Trade-off:** very complex. Use only for specific requirements.

## API style

### REST

Resource-based URLs and standard HTTP methods.

- **When to use:** the default choice for web APIs. Well understood, good tooling.

### GraphQL

A single endpoint; the client specifies the data it needs.

- **When to use:** multiple clients with different data needs, rapid frontend iteration.
- **Trade-off:** complexity, harder caching, N+1 query problems.

### RPC (Remote Procedure Call)

Calling functions across network boundaries.

- **When to use:** internal services, or when REST does not fit the domain well.
