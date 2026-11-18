# Code implementation: worked examples

Before-and-after examples for the naming, function design, error handling and testing steps of the `code-implementation` technique.

## Naming

```javascript
// Bad
const d = new Date();
const u = getU();
function proc(x) { ... }

// Good
const currentDate = new Date();
const currentUser = getCurrentUser();
function processPayment(order) { ... }
```

## Single responsibility

```javascript
// Bad - does too much
function handleUserRegistration(data) {
  validateData(data);
  const user = createUser(data);
  sendWelcomeEmail(user);
  logRegistration(user);
  updateMetrics();
  return user;
}

// Good - orchestrates single-purpose functions
async function registerUser(data) {
  const validData = validateRegistrationData(data);
  const user = createUser(validData);
  await onUserCreated(user); // handles side effects
  return user;
}
```

## Parameters

```javascript
// Bad
function createUser(name, email, isAdmin, sendEmail, logAction) { ... }

// Good
function createUser({ name, email, role }) { ... }
```

## Error handling

```javascript
// Bad
try {
  doSomething();
} catch (e) {
  // silent failure
}

// Good
try {
  doSomething();
} catch (error) {
  logger.error('Failed to do something', { error });
  throw new ApplicationError('Operation failed', { cause: error });
}
```

Fail fast:

```javascript
function processOrder(order) {
  if (!order) throw new Error('Order is required');
  if (!order.items?.length) throw new Error('Order must have items');

  // Now we can work with valid data
  ...
}
```

Meaningful messages:

```javascript
// Bad
throw new Error('Invalid input');

// Good
throw new Error(`Invalid email format: "${email}"`);
```

## Testing behaviour, not implementation

```javascript
// Bad - tests implementation details
test('calls validateEmail with input', () => {
  const spy = jest.spyOn(validator, 'validateEmail');
  registerUser({ email: 'test@example.com' });
  expect(spy).toHaveBeenCalledWith('test@example.com');
});

// Good - tests behavior
test('rejects invalid email addresses', () => {
  expect(() => registerUser({ email: 'invalid' }))
    .toThrow('Invalid email format');
});
```

Test structure:

```javascript
describe('OrderService', () => {
  describe('createOrder', () => {
    it('creates order with valid items', () => { ... });
    it('throws when items array is empty', () => { ... });
    it('calculates total correctly', () => { ... });
  });
});
```
