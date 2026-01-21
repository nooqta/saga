---
name: diagram-generation
description: "Expert guidance for generating UML diagrams in Mermaid format. Use when creating class, sequence, or flow diagrams."
---

# Diagram Generation Skill

Expert guidance for creating UML diagrams using Mermaid syntax.

## When to Use

- During `/saga diagram` command
- When documenting system architecture
- When explaining complex flows

## Diagram Types

### 1. Class Diagram

Shows system structure: classes, properties, methods, relationships.

```mermaid
classDiagram
    class ClassName {
        +string publicProperty
        -int privateProperty
        #bool protectedProperty
        +publicMethod() returnType
        -privateMethod(param) void
    }
```

**Relationships:**
```mermaid
classDiagram
    ClassA --|> ClassB : Inheritance
    ClassA --* ClassB : Composition
    ClassA --o ClassB : Aggregation
    ClassA --> ClassB : Association
    ClassA ..> ClassB : Dependency
    ClassA ..|> InterfaceA : Implements
```

**Multiplicity:**
```mermaid
classDiagram
    User "1" --> "*" Order : places
    Order "1" --> "1..*" OrderItem : contains
```

### 2. Sequence Diagram

Shows interactions over time between participants.

```mermaid
sequenceDiagram
    participant U as User
    participant C as Client
    participant S as Server
    participant D as Database

    U->>C: Action
    C->>S: Request
    activate S
    S->>D: Query
    D-->>S: Result
    S-->>C: Response
    deactivate S
    C-->>U: Display
```

**Control Flow:**
```mermaid
sequenceDiagram
    alt Condition A
        A->>B: Do X
    else Condition B
        A->>B: Do Y
    end

    opt Optional
        A->>B: Maybe do Z
    end

    loop Every minute
        A->>B: Poll
    end

    par Parallel
        A->>B: Task 1
    and
        A->>C: Task 2
    end
```

### 3. Flowchart

Shows process flow and decision points.

```mermaid
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End]
    D --> E
```

**Node Shapes:**
```mermaid
flowchart TD
    A[Rectangle] --> B(Rounded)
    B --> C([Stadium])
    C --> D[[Subroutine]]
    D --> E[(Database)]
    E --> F((Circle))
    F --> G{Diamond}
    G --> H{{Hexagon}}
```

**Directions:**
- `TD` or `TB`: Top to Bottom
- `BT`: Bottom to Top
- `LR`: Left to Right
- `RL`: Right to Left

## Best Practices

### Class Diagrams

1. **Focus on key classes**: Don't include every class
2. **Show important relationships**: Skip trivial dependencies
3. **Group by domain**: Use packages/namespaces
4. **Hide implementation details**: Focus on interfaces

### Sequence Diagrams

1. **One scenario per diagram**: Keep focused
2. **Name participants clearly**: Use roles, not classes
3. **Show happy path first**: Add error flows separately
4. **Limit participants**: 5-7 max for readability

### Flowcharts

1. **Single entry/exit**: Clear start and end
2. **Consistent direction**: Usually top-to-bottom
3. **Label all edges**: Especially decision branches
4. **Subgraphs for grouping**: Use for complex flows

## Codebase Analysis Patterns

When generating from code:

### Finding Classes (TypeScript/JavaScript)
```regex
export\s+(class|interface|type)\s+(\w+)
```

### Finding Methods
```regex
(async\s+)?(\w+)\s*\([^)]*\)\s*[:{]
```

### Finding Relationships
- Imports → Dependencies
- `extends` → Inheritance
- Properties with type → Association
- `new` usage → Dependency

## Common Diagram Templates

### Authentication Flow
```mermaid
sequenceDiagram
    participant User
    participant App
    participant Auth
    participant DB

    User->>App: Enter credentials
    App->>Auth: Validate
    Auth->>DB: Check user
    DB-->>Auth: User data
    Auth->>Auth: Verify password
    alt Valid
        Auth-->>App: Token
        App-->>User: Success
    else Invalid
        Auth-->>App: Error
        App-->>User: Show error
    end
```

### CRUD Entity Flow
```mermaid
flowchart TD
    A[Start] --> B{Action?}
    B -->|Create| C[Validate Input]
    B -->|Read| D[Fetch Data]
    B -->|Update| E[Validate & Update]
    B -->|Delete| F[Confirm & Delete]
    C --> G[Save to DB]
    D --> H[Return Data]
    E --> G
    F --> I[Remove from DB]
    G --> J[Return Success]
    H --> K[End]
    I --> J
    J --> K
```

### Layer Architecture
```mermaid
classDiagram
    class Controller {
        +handleRequest()
    }
    class Service {
        +businessLogic()
    }
    class Repository {
        +dataAccess()
    }
    class Model {
        +properties
    }

    Controller --> Service
    Service --> Repository
    Repository --> Model
```

## Mermaid Limitations

- No overlapping relationships (use subgraphs)
- Limited styling options
- Some complex UML not supported
- Large diagrams can be hard to read

## Output Guidelines

1. **Save to `.saga/diagrams/`**
2. **Use descriptive filenames**: `class.mmd`, `sequence-auth.mmd`
3. **Add comments**: `%% Description`
4. **Include render instructions**: Link to mermaid.live

## Validation

Test diagrams at:
- https://mermaid.live
- GitHub/GitLab markdown preview
- VS Code with Mermaid extension
