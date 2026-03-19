const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.sendFile(__dirname + "index.html");
});

app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

app.listen(3000, () => console.log("Server running on port 3000"));