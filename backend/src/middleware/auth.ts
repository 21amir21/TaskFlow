import { UUID } from "crypto";
import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { db } from "../db";
import { users } from "../db/schema";
import { eq } from "drizzle-orm";

export interface AuthRequest extends Request {
  user?: UUID;
  token?: string;
}

export const auth = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    // get the header to verify if the token is valid
    const token = req.header("x-auth-token"); // "Authorization" can also be used!

    if (!token) {
      res.status(401).json({ error: "No auth token, access denied!!" });
      return;
    }

    const verified = jwt.verify(token, "passwordKey");

    if (!verified) {
      res.status(401).json({ error: "Token verification faild!!" });
      return;
    }

    // get the user data if the token is valid
    const verifiedToken = verified as { id: UUID };

    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, verifiedToken.id));
    // if no user, return false
    if (!user) {
      res.status(401).json({ error: "User not found!!" });
      return;
    }

    req.user = verifiedToken.id;
    req.token = token;
    next();
  } catch (err) {
    res.status(500).json({ error: err });
  }
};
