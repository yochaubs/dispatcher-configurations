module.exports.readVersion = function (contents) {
  const regEx = /<revision>(.*)<\/revision>/;
  const arr = regEx.exec(contents);
  console.log(JSON.stringify(arr));
  if (arr !== null && arr.length === 2) {
    return arr[1];
  }

  return '';
};

module.exports.writeVersion = function (contents, version) {
  return contents.replace(/<revision>.*<\/revision>/, '<revision>' + version + '</revision>');
};
