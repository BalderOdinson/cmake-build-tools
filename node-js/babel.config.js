const originalResolvePath = require('babel-plugin-module-resolver').resolvePath;
const path = require('path');

const babelRc = "@babelrc@";
const imports = @imports@;

let extendsBabelRc = undefined;
if (babelRc) {
    extendsBabelRc = path.posix.resolve(path.relative(process.cwd(), babelRc));
}

module.exports = {
    extends: extendsBabelRc,
    plugins: [
        [
            'module-resolver',
            {
                resolvePath(sourcePath, currentFile, opts) {
                    if (Object.keys(imports).includes(sourcePath)) {
                        return imports[sourcePath];
                    }
                    return originalResolvePath(sourcePath, currentFile, opts);
                },
            },
            'module-resolver-resources',
        ]
    ]
}
