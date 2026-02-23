---
name: testing-uat-playwright
parent_adr: DEV-001
status: active
work_types: [new-feature, new-page, user-story]
created: 2026-02-05
usage_count: 0
---

# testing-uat-playwright

User Acceptance Testing pattern using Playwright for E2E browser tests.

## When

After implementing UI features that have user stories with acceptance criteria.

## Structure

```
src/test/uat/
├── scenarios/           # E2E test specs (*.uat.spec.ts)
├── fixtures/            # Test data and user states
└── utils/
    ├── pages/           # Page Object Models
    └── helpers.ts       # Common test utilities
```

## Configuration

`playwright.config.ts`:
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './src/test/uat/scenarios',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'playwright-report/results.json' }],
    process.env.CI ? ['github'] : ['list'],
  ],
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10000,
    navigationTimeout: 30000,
  },
  timeout: 60000,
  expect: { timeout: 10000 },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
    { name: 'mobile-safari', use: { ...devices['iPhone 12'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
```

## Template: Scenario

`scenarios/{feature}.uat.spec.ts`:
```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../utils/pages/LoginPage';
import { {Feature}Page } from '../utils/pages/{Feature}Page';
import { testUsers } from '../fixtures/users';

test.describe('User Story: {Story Title}', () => {
  let loginPage: LoginPage;
  let featurePage: {Feature}Page;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    featurePage = new {Feature}Page(page);

    // Login as appropriate user
    await loginPage.goto();
    await loginPage.login(testUsers.instructor);
  });

  test('AC1: {Acceptance Criterion}', async ({ page }) => {
    // Given: preconditions
    await featurePage.goto();

    // When: user action
    await featurePage.performAction();

    // Then: verify outcome
    await expect(featurePage.successMessage).toBeVisible();
  });

  test('AC2: {Another Criterion}', async ({ page }) => {
    // Given/When/Then...
  });
});
```

## Template: Page Object

`utils/pages/{Feature}Page.ts`:
```typescript
import { type Page, type Locator } from '@playwright/test';

export class {Feature}Page {
  readonly page: Page;

  // Locators
  readonly heading: Locator;
  readonly submitButton: Locator;
  readonly successMessage: Locator;
  readonly errorAlert: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: '{Feature}' });
    this.submitButton = page.getByRole('button', { name: 'Submit' });
    this.successMessage = page.getByTestId('success-message');
    this.errorAlert = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/{feature-path}');
  }

  async performAction(data?: any) {
    // Encapsulate multi-step interactions
    await this.submitButton.click();
  }

  async fillForm(data: {Feature}FormData) {
    // Fill form fields
  }
}
```

## Template: Fixtures

`fixtures/{feature}.ts`:
```typescript
export const test{Feature}Data = {
  valid: {
    title: 'Test {Feature}',
    description: 'Test description',
  },
  invalid: {
    title: '', // Missing required field
  },
};

export const test{Feature}States = {
  empty: [],
  withItems: [
    { id: '1', title: 'Item 1' },
    { id: '2', title: 'Item 2' },
  ],
};
```

## Commands

```bash
# Run all UAT tests
npm run e2e

# Run with UI mode (debugging)
npx playwright test --ui

# Run specific scenario
npx playwright test {feature}.uat.spec.ts

# Run in headed mode
npx playwright test --headed

# Run specific browser
npx playwright test --project=chromium

# Generate report
npx playwright show-report

# Update snapshots
npx playwright test --update-snapshots
```

## Checklist

- [ ] Scenario file follows `{feature}.uat.spec.ts` naming
- [ ] Tests map to user story acceptance criteria
- [ ] Page Objects encapsulate all page interactions
- [ ] Use `data-testid` attributes for stable selectors
- [ ] Tests are independent (no shared state)
- [ ] Fixtures provide consistent test data
- [ ] Descriptive test names match story language

## Best Practices

1. **Selectors priority**: `data-testid` > role > text > css
2. **Wait strategies**: Prefer `expect().toBeVisible()` over arbitrary waits
3. **Test isolation**: Each test should work independently
4. **Page Objects**: One per logical page/component
5. **Fixtures**: Separate valid/invalid/edge-case data

## Lessons

- 2026-02-05: UAT testing added alongside unit tests for complete coverage
