const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
    const browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();
    
    const htmlPath = path.resolve(__dirname, 'schema_diagram.html');
    await page.goto('file://' + htmlPath, { waitUntil: 'networkidle0', timeout: 30000 });
    
    await page.pdf({
        path: path.resolve(__dirname, 'RideShare_Schema_Diagram.pdf'),
        width: '3200px',
        height: '2000px',
        printBackground: true,
        margin: { top: 0, right: 0, bottom: 0, left: 0 }
    });
    
    console.log('PDF generated: RideShare_Schema_Diagram.pdf');
    await browser.close();
})();
