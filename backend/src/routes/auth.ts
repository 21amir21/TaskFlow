import { Request, Response, Router } from "express";
import { db } from "../db";
import { NewUser, users } from "../db/schema";
import { eq } from "drizzle-orm";
import bcryptjs from "bcryptjs";
import jwt from "jsonwebtoken";
import { auth, AuthRequest } from "../middleware/auth";

const authRouter = Router();

interface SignUpBody {
  name: string;
  email: string;
  password: string;
}

interface LoginBody {
  email: string;
  password: string;
}

authRouter.post(
  "/signup",
  async (req: Request<{}, {}, SignUpBody>, res: Response) => {
    try {
      // get the req body
      const { name, email, password } = req.body;
      // check if the user exists
      const existingUser = await db
        .select()
        .from(users)
        .where(eq(users.email, email));

      if (existingUser.length) {
        res.status(400).json({ msg: "User with the same email exists!!" });
        return;
      }
      // hash the password
      const hashedPassword = await bcryptjs.hash(password, 8);
      // create a new user and store it in the db
      const newUser: NewUser = {
        name,
        email,
        password: hashedPassword,
      };

      const [user] = await db.insert(users).values(newUser).returning();
      res.status(201).json(user);
    } catch (err) {
      res.status(500).json({ error: err });
    }
  }
);

authRouter.post(
  "/login",
  async (req: Request<{}, {}, LoginBody>, res: Response) => {
    try {
      // get the req body
      const { email, password } = req.body;
      // check if the user exists
      const [existingUser] = await db
        .select()
        .from(users)
        .where(eq(users.email, email));

      if (!existingUser) {
        res.status(400).json({ msg: "User with this email does not exist!!" });
        return;
      }
      // hash the password
      const isMatch = await bcryptjs.compare(password, existingUser.password);

      if (!isMatch) {
        res.status(400).json({ msg: "Incorrect password!!" });
        return;
      }

      const token = jwt.sign({ id: existingUser.id }, "passwordKey");

      res.status(200).json({ token, ...existingUser });
    } catch (err) {
      res.status(500).json({ error: err });
    }
  }
);

authRouter.post("/tokenIsValid", async (req, res) => {
  try {
    // get the header to verify if the token is valid
    const token = req.header("x-auth-token"); // "Authorization" can also be used!

    if (!token) {
      res.json(false);
      return;
    }

    const verified = jwt.verify(token, "passwordKey");

    if (!verified) {
      res.json(false);
      return;
    }

    // get the user data if the token is valid
    const verifiedToken = verified as { id: string };

    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, verifiedToken.id));
    // if no user, return false
    if (!user) {
      res.json(false);
      return;
    }

    res.json(true);
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

authRouter.get("/", auth, async (req: AuthRequest, res) => {
  try {
    if (!req.user) {
      res.status(401).json({ error: "User not found!" });
      return;
    }

    const [user] = await db.select().from(users).where(eq(users.id, req.user));

    res.json({ ...user, token: req.token });
  } catch (err) {
    res.status(500).json(false);
  }
});

export default authRouter;
