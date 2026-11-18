# Worked example: shared state in a layout context

Use case: every view under one shell needs the signed-in user and the currently selected account. Both change rarely, and both are needed by the navigation and by each page. The provider lives in the shared layout of a route group, so it wraps every view in the group and nothing outside it.

```typescript
// app/(workspace)/layout.tsx
'use client';

import { createContext, useContext, useEffect, useState } from 'react';

interface WorkspaceContextValue {
  user: WorkspaceUser | null;
  selectedAccount: string | null;
  setSelectedAccount: (id: string | null) => void;
}

const WorkspaceContext = createContext<WorkspaceContextValue>({
  user: null,
  selectedAccount: null,
  setSelectedAccount: () => {},
});

export function useWorkspace() {
  return useContext(WorkspaceContext);
}

export default function WorkspaceLayout({ children }) {
  const [user, setUser] = useState<WorkspaceUser | null>(null);
  const [selectedAccount, setSelectedAccount] = useState<string | null>(null);

  // Load auth on mount
  useEffect(() => {
    const init = async () => {
      const authUser = await getAuthUser();
      setUser(authUser);
      // A non-admin user belongs to exactly one account, so select it for them.
      if (!authUser.isAdmin && authUser.accountId) {
        setSelectedAccount(authUser.accountId);
      }
    };
    init();
  }, []);

  return (
    <WorkspaceContext.Provider value={{ user, selectedAccount, setSelectedAccount }}>
      <TopNav />
      <main>{children}</main>
    </WorkspaceContext.Provider>
  );
}
```

Usage in a child component:

```typescript
// components/workspace/TopNav.tsx
'use client';

import { useWorkspace } from '@/app/(workspace)/layout';

export function TopNav() {
  const { user, selectedAccount, setSelectedAccount } = useWorkspace();

  return (
    <nav>
      <AccountSelector value={selectedAccount} onChange={setSelectedAccount} />
      {user?.isAdmin && <Link href="/admin">Admin</Link>}
    </nav>
  );
}
```

What makes this a fit for context:

- The values change rarely (sign-in, an occasional account switch), so the re-render of every consumer is cheap.
- Every view under the shell needs them, so passing props would mean threading them through each page.
- The active record inside a view (a session, a document) is not in this context. It is in the URL.
