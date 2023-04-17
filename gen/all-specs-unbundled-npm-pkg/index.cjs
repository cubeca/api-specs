const path = require('node:path');

module.exports = {
    bffApiSpecFile: path.join(__dirname, 'specs/bff.json'),
    bffAuthApiSpecFile: path.join(__dirname, 'specs/bff-auth.json'),
}
