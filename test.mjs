import fs, { readdir } from "fs"
import fsPromises from "fs/promises"
import { exec as exec_ } from "child_process"
import util from 'util'

const exec = util.promisify(exec_);

async function rebuildIfNecessary(filenames) {
  console.log(filenames)
  await filenames.forEach(filename => {
    const prefix = filename.substring(0, filename.indexOf('.'));

    if (fs.existsSync(`build/${prefix}.cfs`) &&
      lastModfiedDate(`build/${prefix}.cfs`) < lastRanTest(prefix) &&
      hash(`build/${prefix}.cfs`) == lastRanHash(prefix)) {} else {
      exec(`npx jison -o build/${prefix}.cjs --main src/${prefix}.jison`);
    }
  });
}

fsPromises.readdir('test')
  .then(filenames => {
    return filenames.filter(filename => {
      return filename.endsWith('.test.mjs')
    })
  })
  .then(filenames => {
    rebuildIfNecessary(filenames);
    return filenames;
  })
  .then(filenames => {
    const promises = []
    filenames.forEach(filename => {
      const prefix = filename.substring(0, filename.indexOf('.'));
      promises.push(exec(`npx mocha test/${prefix}.test.mjs`))
    });
    return Promise.all(promises);
  })
  .catch(reason => {
    console.error(reason);
  });