import { Router } from "express";

const authRouter = Router();

authRouter.get("/", (req, res) => {
  res.send("Hey there from auth!!");
});

export default authRouter;
