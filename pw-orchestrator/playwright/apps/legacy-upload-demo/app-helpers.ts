import { Page } from '@playwright/test';
import { getConfig } from '../../helpers/discovery';

/**
 * App-specific helpers for legacy-upload-demo (OGE Field Operations).
 *
 * These helpers encode knowledge about this specific app's UI structure,
 * navigation patterns, and validation behavior. Generic test utilities
 * live in helpers/test-utils.ts.
 */

/**
 * Navigate to an outage's upload page by discovering it through the UI.
 * Does NOT hard-code an outage ID — finds the first available via the Outages list.
 */
export async function navigateToUploadPage(page: Page): Promise<void> {
  const config = getConfig();

  await page.goto(config.listRoute);

  // Preflight: verify the list page has at least one Upload link
  const uploadLink = page.getByRole('link', { name: 'Upload' }).first();
  const linkCount = await page.getByRole('link', { name: 'Upload' }).count();
  if (linkCount === 0) {
    throw new Error(
      `No "Upload" links found on ${config.listRoute}. ` +
      `The app must have at least one record with an upload action. ` +
      `Seed the app with test data before running the suite.`
    );
  }

  await uploadLink.click();
  await page.getByRole('heading', { name: /upload/i }).waitFor();
}

/**
 * Get the URL pattern for the upload page in this app.
 */
export function uploadPagePattern(): RegExp {
  const config = getConfig();
  // Convert route template like /Outages/Upload/{id} to regex /\/Outages\/Upload\/\d+/
  const escaped = config.uploadRoute
    .replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    .replace('\\{id\\}', '\\d+');
  return new RegExp(escaped);
}

/**
 * Get the URL pattern for the details/success page after upload.
 * This is app-specific knowledge about the legacy-upload-demo's routing convention.
 */
export function detailsPagePattern(): RegExp {
  const config = getConfig();
  // App-specific: this app uses /Controller/Details/{id} alongside /Controller/Upload/{id}
  const detailsRoute = config.uploadRoute.replace(/\/[^/]+\/\{id\}$/, '/Details/{id}');
  const escaped = detailsRoute
    .replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    .replace('\\{id\\}', '\\d+');
  return new RegExp(escaped);
}

/**
 * Detect app-specific failure signals for this legacy app.
 * Includes ASP.NET MVC validation summary and Bootstrap danger alerts.
 */
export async function hasAppFailureSignal(page: Page): Promise<boolean> {
  const config = getConfig();

  const signals = [
    page.locator('.validation-summary-errors'),
    page.locator('.text-danger'),
    page.getByText(config.validationError),
  ];

  for (const signal of signals) {
    if (await signal.first().isVisible({ timeout: 3000 }).catch(() => false)) {
      return true;
    }
  }
  return false;
}
