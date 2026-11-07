import { Request, Response } from 'express';
import { ApiResponse } from '../utils/apiResponse';
import { getProfile, updateProfile } from '../services/profile.service';

const owner = (res: Response): string => res.locals.userId;
export async function readProfile(_req: Request, res: Response) { return ApiResponse.success(res, await getProfile(owner(res))); }
export async function patchProfile(req: Request, res: Response) { return ApiResponse.success(res, await updateProfile(owner(res), req.body)); }
