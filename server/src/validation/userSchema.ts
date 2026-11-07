import { JSONSchemaType } from 'ajv';

export interface CreateUserDto {
  name: string;
  email: string;
  age?: number;
}

export interface UpdateUserDto {
  name?: string;
  email?: string;
  age?: number;
}

export const createUserSchema: JSONSchemaType<CreateUserDto> = {
  type: 'object',
  properties: {
    name: { type: 'string', minLength: 1, maxLength: 100 },
    email: { type: 'string', format: 'email' },
    age: { type: 'number', minimum: 0, maximum: 150, nullable: true },
  },
  required: ['name', 'email'],
  additionalProperties: false,
};

export const updateUserSchema: JSONSchemaType<UpdateUserDto> = {
  type: 'object',
  properties: {
    name: { type: 'string', minLength: 1, maxLength: 100, nullable: true },
    email: { type: 'string', format: 'email', nullable: true },
    age: { type: 'number', minimum: 0, maximum: 150, nullable: true },
  },
  required: [],
  additionalProperties: false,
};
