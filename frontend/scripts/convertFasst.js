const fs = require("fs");
const path = require("path");

const inputPath = path.join(__dirname, "../src/assets/output-files/fasst.out");
const outputPath = path.join(__dirname, "../src/assets/converted-outputs/fasst.json");

const raw = fs.readFileSync(inputPath, "utf8");
const lines = raw.split(/\r?\n/).filter(line => line.trim() !== "");

// Fasst structure:
// line 0 → junk
// line 1 → headers
// line 2 → units (ignore)
// line 3+ → numeric data
const headers = lines[1].trim().split(/\s+/);
const dataLines = lines.slice(3);

const data = dataLines.map(line => {
  const values = line.trim().split(/\s+/);
  let row = {};
  headers.forEach((h, i) => {
    if (values[i] !== undefined) {
      row[h] = isNaN(values[i]) ? values[i] : parseFloat(values[i]);
    }
  });
  return row;
});

fs.writeFileSync(outputPath, JSON.stringify(data, null, 2));
console.log(`✅ Parsed ${data.length} rows → ${outputPath}`);
