import { Page } from '@playwright/test';
import { getConfig } from './discovery';

/**
 * Generate a unique filename for a test scenario to avoid cross-run collisions.
 */
export function uniqueFilename(prefix: string, extension: string): string {
  const ts = Date.now();
  const rand = Math.random().toString(36).substring(2, 8);
  return `${prefix}-${ts}-${rand}${extension}`;
}

/**
 * Create an in-memory file buffer for upload (no external fixture dependency).
 */
export function createFileBuffer(sizeBytes: number, content?: string): Buffer {
  if (content) {
    return Buffer.from(content, 'utf-8');
  }
  return Buffer.alloc(sizeBytes, 'x');
}

/**
 * Navigate to an outage's upload page by discovering it through the UI.
 * Does NOT hard-code an outage ID — finds the first available via the Outages list.
 */
export async function navigateToUploadPage(page: Page): Promise<void> {
  await page.goto('/Outages');
  // Click the first "Upload" action link in the outage table
  const uploadLink = page.getByRole('link', { name: 'Upload' }).first();
  await uploadLink.click();
  // Verify we're on the upload page by checking for the heading
  await page.getByRole('heading', { name: /upload/i }).waitFor();
}

/**
 * Upload a file on the upload page using Playwright's file chooser API.
 * Uses label-based locator for the file input (accessible pattern).
 */
export async function uploadFile(
  page: Page,
  fileName: string,
  content: Buffer,
  mimeType: string = 'application/octet-stream'
): Promise<void> {
  const fileInput = page.getByLabel('File');
  await fileInput.setInputFiles({
    name: fileName,
    mimeType,
    buffer: content,
  });
  await page.getByRole('button', { name: 'Upload' }).click();
}

/**
 * Detect any visible failure signal on the page after an upload attempt.
 * Checks for validation messages, error text, or HTTP error indicators.
 */
export async function hasVisibleFailureSignal(page: Page): Promise<boolean> {
  const config = getConfig();

  const signals = [
    page.locator('.text-danger'),
    page.locator('.validation-summary-errors'),
    page.getByText(/maximum|too large|not allowed|error/i),
    page.getByText(config.validationError),
  ];

  for (const signal of signals) {
    if (await signal.first().isVisible({ timeout: 3000 }).catch(() => false)) {
      return true;
    }
  }
  return false;
}
