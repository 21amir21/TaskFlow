import express from "express";
import authRouter from "./routes/auth";
import taskRouter from "./routes/task";
import path from "path";

const app = express();

// Serve images statically
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.use(express.json());
app.use("/auth", authRouter);
app.use("/tasks", taskRouter);

app.get("/", (req, res) => {
  res.send("Welcome to TaskFlow");
});

app.listen(8000, () => {
  console.log("Server started on port 8000");
});
