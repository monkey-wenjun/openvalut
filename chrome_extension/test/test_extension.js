const puppeteer = require('puppeteer-core');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: '/usr/bin/google-chrome',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      `--load-extension=<repo>/chrome_extension`,
      `--disable-extensions-except=<repo>/chrome_extension`,
    ],
  });

  const page = await browser.newPage();
  await page.goto('https://admin.example.com/', { waitUntil: 'networkidle2' });

  // Wait a bit for content script to run at document_idle.
  await new Promise((r) => setTimeout(r, 1500));

  const injected = await page.evaluate(() => {
    return {
      injected: typeof window.__openvalutContentScriptInjected !== 'undefined',
      combos: (typeof combos !== 'undefined' ? combos.length : 'N/A'),
    };
  });

  console.log('Content script injected:', injected.injected);
  console.log('Detected combos:', injected.combos);

  // Listen for console messages from the page.
  page.on('console', (msg) => console.log('PAGE CONSOLE:', msg.text()));

  // Keep browser open for manual inspection.
  console.log('Browser is open. Press Ctrl+C to close.');
})();
