import { Router } from "express";
import { auth, AuthRequest } from "../middleware/auth";
import { NewTask, tasks } from "../db/schema";
import { db } from "../db";
import { eq } from "drizzle-orm";

const taskRouter = Router();

taskRouter.post("/", auth, async (req: AuthRequest, res) => {
  try {
    // create a new task in db
    req.body = { ...req.body, dueAt: new Date(req.body.dueAt), uid: req.user };
    const newTask: NewTask = req.body;

    const [task] = await db.insert(tasks).values(newTask).returning();

    res.status(201).json(task);
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

taskRouter.get("/", auth, async (req: AuthRequest, res) => {
  try {
    const allTasks = await db
      .select()
      .from(tasks)
      .where(eq(tasks.uid, req.user!));

    res.status(200).json(allTasks);
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

taskRouter.delete("/", auth, async (req: AuthRequest, res) => {
  try {
    const { taskID }: { taskID: string } = req.body;
    await db.delete(tasks).where(eq(tasks.id, taskID));

    res.status(200).json(true);
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

export default taskRouter;
