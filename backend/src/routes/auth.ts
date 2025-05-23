import { Request, Response, Router } from "express";
import { db } from "../db";
import { NewUser, users } from "../db/schema";
import { eq } from "drizzle-orm";
import bcryptjs from "bcryptjs";
import jwt from "jsonwebtoken";
import { auth, AuthRequest } from "../middleware/auth";
import { upload } from "../middleware/multerConfig";
import path from "path";
import fs from "fs";

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
        res.status(400).json({ error: "User with the same email exists!!" });
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
        res
          .status(400)
          .json({ error: "User with this email does not exist!!" });
        return;
      }
      // hash the password
      const isMatch = await bcryptjs.compare(password, existingUser.password);

      if (!isMatch) {
        res.status(400).json({ error: "Incorrect password!!" });
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

authRouter.post(
  "/change-password",
  auth,
  async (req: AuthRequest, res: Response) => {
    try {
      const { currentPassword, newPassword } = req.body;

      if (!req.user) {
        res.status(401).json({ error: "Unauthorized" });
        return;
      }

      const [user] = await db
        .select()
        .from(users)
        .where(eq(users.id, req.user));

      if (!user) {
        res.status(404).json({ error: "User not found" });
        return;
      }

      const isMatch = await bcryptjs.compare(currentPassword, user.password);

      if (!isMatch) {
        res.status(400).json({ error: "Current password is incorrect" });
        return;
      }

      const hashedNewPassword = await bcryptjs.hash(newPassword, 8);

      await db
        .update(users)
        .set({ password: hashedNewPassword })
        .where(eq(users.id, req.user));

      res.status(200).json({ message: "Password updated successfully" });
    } catch (err) {
      res.status(500).json({ error: "Server error" });
    }
  }
);

authRouter.put(
  "/update-profile",
  auth,
  async (req: AuthRequest, res: Response) => {
    try {
      const { name, email } = req.body;

      if (!req.user) {
        res.status(401).json({ error: "Unauthorized" });
        return;
      }

      await db.update(users).set({ name, email }).where(eq(users.id, req.user));

      const [updatedUser] = await db
        .select()
        .from(users)
        .where(eq(users.id, req.user));

      res.status(200).json(updatedUser);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "Failed to update profile" });
    }
  }
);

authRouter.post(
  "/upload-profile-image",
  auth,
  upload.single("image"),
  async (req: AuthRequest, res: Response) => {
    try {
      if (!req.file) {
        res.status(400).json({ error: "No image uploaded" });
      }

      const imageUrl = `${req.protocol}://${req.get("host")}/uploads/${
        req.file?.filename
      }`;
      res.status(200).json({ imageUrl });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Failed to upload image" });
    }
  }
);

authRouter.put(
  "/update-profile-image",
  auth,
  async (req: AuthRequest, res: Response) => {
    try {
      const { profileImage } = req.body;

      if (!req.user) {
        res.status(401).json({ error: "Unauthorized" });
      }

      await db
        .update(users)
        .set({ profileImage })
        .where(eq(users.id, req.user as string));

      const [updatedUser] = await db
        .select()
        .from(users)
        .where(eq(users.id, req.user as string));

      res.status(200).json(updatedUser);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "Failed to update profile image" });
    }
  }
);

authRouter.put(
  "/remove-profile-image",
  auth,
  async (req: AuthRequest, res: Response) => {
    try {
      if (!req.user) {
        res.status(401).json({ error: "Unauthorized" });
      }

      const userId = req.user as string;

      // Find the user in the database
      const [user] = await db.select().from(users).where(eq(users.id, userId));

      if (!user) {
        res.status(404).json({ error: "User not found" });
      }

      // If the user has a profile image, remove it
      if (user.profileImage) {
        const imagePath = path.join(
          __dirname,
          "..",
          "uploads",
          user.profileImage
        );

        // Remove file if it exists
        if (fs.existsSync(imagePath)) {
          fs.unlinkSync(imagePath);
        }

        // Update the user record to remove the profile image
        await db
          .update(users)
          .set({ profileImage: "" })
          .where(eq(users.id, userId));
      }

      // Get the updated user record and send it back
      const [updatedUser] = await db
        .select()
        .from(users)
        .where(eq(users.id, userId));

      res.status(200).json(updatedUser);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "Failed to remove profile image" });
    }
  }
);

export default authRouter;
