import { Router } from "express";
import { UserController } from "../controllers";
import { validateRequest } from "../middleware/validateRequest";
import { createUserSchema, updateUserSchema } from "../validation";

const router = Router();
const userController = new UserController();

router.get("/", userController.getAllUsers);
router.get("/:id", userController.getUserById);
router.post("/", validateRequest(createUserSchema), userController.createUser);
router.put(
  "/:id",
  validateRequest(updateUserSchema),
  userController.updateUser,
);
router.delete("/:id", userController.deleteUser);

export default router;
