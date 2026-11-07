import Ajv, { JSONSchemaType } from 'ajv';
import addFormats from 'ajv-formats';
import addKeywords from 'ajv-keywords';
import { NextFunction, Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';

const ajv = new Ajv({ allErrors: true, removeAdditional: true });
addFormats(ajv);
addKeywords(ajv);

export const validateRequest = <T>(schema: JSONSchemaType<T>) => {
  const validate = ajv.compile(schema);

  return (req: Request, res: Response, next: NextFunction): void => {
    const valid = validate(req.body);

    if (!valid) {
      const errors = validate.errors?.map((err) => ({
        field: err.instancePath.replace('/', ''),
        message: err.message,
      }));

      res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'Validation failed',
        errors,
      });
      return;
    }

    next();
  };
};
