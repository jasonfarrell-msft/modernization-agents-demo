import { Page } from '@playwright/test';

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
 * Upload a file via a standard HTML file input and submit button.
 * Uses label-based locator for the file input (accessible pattern).
 */
export async function uploadFile(
  page: Page,
  fileName: string,
  content: Buffer,
  options: {
    fileInputLabel?: string;
    submitButtonName?: string;
    mimeType?: string;
  } = {}
): Promise<void> {
  const {
    fileInputLabel = 'File',
    submitButtonName = 'Upload',
    mimeType = 'application/octet-stream',
  } = options;

  const fileInput = page.getByLabel(fileInputLabel);
  await fileInput.setInputFiles({
    name: fileName,
    mimeType,
    buffer: content,
  });
  await page.getByRole('button', { name: submitButtonName }).click();
}

/**
 * Detect any visible failure signal on the page after a form submission.
 * Checks common error patterns: validation summaries, error text, danger alerts.
 * Pass app-specific error patterns via the `patterns` parameter.
 */
export async function hasVisibleFailureSignal(
  page: Page,
  patterns: RegExp[] = []
): Promise<boolean> {
  const defaultPatterns = [
    /maximum|too large|not allowed|error|invalid|rejected/i,
  ];

  const allPatterns = [...defaultPatterns, ...patterns];

  // Check common error container roles/elements
  const errorContainers = [
    page.getByRole('alert'),
    page.locator('[role="alert"]'),
  ];

  for (const container of errorContainers) {
    if (await container.first().isVisible({ timeout: 3000 }).catch(() => false)) {
      return true;
    }
  }

  // Check text patterns
  for (const pattern of allPatterns) {
    if (await page.getByText(pattern).first().isVisible({ timeout: 1000 }).catch(() => false)) {
      return true;
    }
  }

  return false;
}
