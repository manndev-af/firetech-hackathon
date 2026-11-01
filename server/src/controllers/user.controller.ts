import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import { ApiResponse } from '../utils/apiResponse';
import { AppError } from '../utils/appError';
import { asyncErrorHandler } from '../utils/asyncErrorHandler';

// Demo user data (replace with actual database calls)
let users = [
  { id: '1', name: 'John Doe', email: 'john@example.com', age: 30 },
  { id: '2', name: 'Jane Smith', email: 'jane@example.com', age: 25 },
];

export class UserController {
  public getAllUsers = asyncErrorHandler(async (req: Request, res: Response) => {
    return ApiResponse.success(res, users, 'Users retrieved successfully');
  });

  public getUserById = asyncErrorHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const user = users.find(u => u.id === id);

    if (!user) {
      throw new AppError('User not found', StatusCodes.NOT_FOUND);
    }

    return ApiResponse.success(res, user, 'User retrieved successfully');
  });

  public createUser = asyncErrorHandler(async (req: Request, res: Response) => {
    const { name, email, age } = req.body;

    const newUser = {
      id: String(users.length + 1),
      name,
      email,
      age,
    };

    users.push(newUser);

    return ApiResponse.created(res, newUser, 'User created successfully');
  });

  public updateUser = asyncErrorHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const updates = req.body;

    const userIndex = users.findIndex(u => u.id === id);

    if (userIndex === -1) {
      throw new AppError('User not found', StatusCodes.NOT_FOUND);
    }

    users[userIndex] = { ...users[userIndex], ...updates };

    return ApiResponse.success(res, users[userIndex], 'User updated successfully');
  });

  public deleteUser = asyncErrorHandler(async (req: Request, res: Response) => {
    const { id } = req.params;

    const userIndex = users.findIndex(u => u.id === id);

    if (userIndex === -1) {
      throw new AppError('User not found', StatusCodes.NOT_FOUND);
    }

    users = users.filter(u => u.id !== id);

    return ApiResponse.noContent(res);
  });
}
