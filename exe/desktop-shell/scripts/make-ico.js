const pngToIco = require('png-to-ico');
const fs = require('fs');
const path = require('path');

const png = path.join(__dirname, '..', 'assets', 'app-icon.png');
const ico = path.join(__dirname, '..', 'assets', 'app-icon.ico');

pngToIco(png)
  .then((buf) => {
    fs.writeFileSync(ico, buf);
    console.log('Icono .ico generado:', ico);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
