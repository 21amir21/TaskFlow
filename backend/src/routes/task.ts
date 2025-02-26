import { Router } from "express";
import { auth, AuthRequest } from "../middleware/auth";

const taskRouter = Router();

taskRouter.post("/", auth, async (req: AuthRequest, res) => {
  try {
    // create a new task in db
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

export default taskRouter;
