// index.js
const express = require("express");

const app = express();

app.get("/health", (_req, res) => {
  res.status(200).send("ok");
});

const port = process.env.PORT || 8080;
app.listen(port, '0.0.0.0', () => {
  console.log(`Server listening on port ${port}`);
});
