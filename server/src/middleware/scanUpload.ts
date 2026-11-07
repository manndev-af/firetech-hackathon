import { Request, Response, NextFunction } from "express";
import multer from "multer";
import sharp from "sharp";
import { ajv } from "../validation/nutrition";
import { DomainError } from "../utils/domainError";
import { scannerConfig } from "../config/scanner";

export const maxImageBytes = 5 * 1024 * 1024;
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: maxImageBytes,
    files: 1,
    fields: 5,
    parts: 6,
    fieldSize: 80000,
    fieldNameSize: 64,
  },
}).single("image");
let active = 0;
export function scanSlot(_req: Request, res: Response, next: NextFunction) {
  if (active >= 2)
    return next(
      new DomainError(
        "SCAN_BUSY",
        "Scanner sedang sibuk. Coba lagi nanti.",
        429,
      ),
    );
  active++;
  let released = false;
  const release = () => {
    if (!released) {
      active--;
      released = true;
    }
  };
  res.locals.releaseScanSlot = release;
  res.once("finish", release);
  // A disconnected client must not release an in-flight provider operation.
  res.once("close", () => {
    if (!res.locals.scanRunning) release();
  });
  next();
}

export function scanUpload(req: Request, res: Response, next: NextFunction) {
  if (!req.is("multipart/form-data"))
    return next(
      new DomainError(
        "INVALID_CONTENT_TYPE",
        "Gunakan multipart/form-data.",
        415,
      ),
    );
  if (Number(req.get("content-length")) > 6 * 1024 * 1024)
    return next(
      new DomainError("UPLOAD_TOO_LARGE", "Upload melebihi 6 MiB.", 413),
    );
  upload(req, res, (error) => {
    if (error) {
      delete req.file;
      return next(
        new DomainError(
          "INVALID_UPLOAD",
          "Upload melebihi batas atau field tidak sesuai.",
          error.code?.includes("LIMIT") ? 413 : 400,
        ),
      );
    }
    next();
  });
}

export const scanMetadataSchema = {
  type: "object",
  additionalProperties: false,
  required: ["mode"],
  properties: {
    mode: { type: "string", enum: ["food", "label"] },
    description: { type: "string", maxLength: 1000 },
    rawOcrText: { type: "string", maxLength: 20000 },
    consumedAt: { type: "string", format: "date-time" },
    quantity: { type: "string", pattern: "^(?:[0-9]{1,5})(?:\\.[0-9]{1,6})?$" },
  },
};
export type ScanInput = {
  mode: "food" | "label";
  description: string;
  rawOcrText: string;
  quantity: number;
  consumedAt: Date;
  fingerprintMetadata: object;
  key: string;
  original: Buffer;
  image: Buffer;
};

export async function readScanInput(req: Request): Promise<ScanInput> {
  const key = req.get("Idempotency-Key") || "";
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      key,
    )
  )
    throw new DomainError(
      "INVALID_IDEMPOTENCY_KEY",
      "Idempotency-Key UUID wajib diisi.",
    );
  if (!ajv.validate(scanMetadataSchema, req.body))
    throw new DomainError("INVALID_INPUT", "Metadata scan tidak valid.");
  const mode = req.body.mode as "food" | "label";
  const description = (req.body.description || "").trim();
  const rawOcrText = (req.body.rawOcrText || "").trim();
  if (mode === "label" && scannerConfig().useRawOcr && !rawOcrText)
    throw new DomainError("OCR_REQUIRED", "Raw OCR wajib pada mode label.");
  const quantity =
    req.body.quantity === undefined ? 1 : Number(req.body.quantity);
  if (!(quantity >= 0.000001 && quantity <= 10000))
    throw new DomainError(
      "INVALID_QUANTITY",
      "Jumlah porsi harus lebih dari nol dan maksimal 10000.",
    );
  const consumedAt = req.body.consumedAt
    ? new Date(req.body.consumedAt)
    : new Date();
  if (consumedAt.getUTCFullYear() < 2000 || consumedAt.getUTCFullYear() > 2100)
    throw new DomainError(
      "INVALID_DATE",
      "Waktu konsumsi di luar rentang yang didukung.",
    );
  const file = req.file;
  if (!file || !file.size)
    throw new DomainError("IMAGE_REQUIRED", "Satu gambar wajib diunggah.");
  try {
    const decoder = sharp(file.buffer, {
      limitInputPixels: 20000000,
      failOn: "warning",
      animated: false,
    });
    const metadata = await decoder.metadata();
    const expected =
      metadata.format === "jpeg"
        ? "image/jpeg"
        : metadata.format === "png"
          ? "image/png"
          : "";
    if (!expected || expected !== file.mimetype || (metadata.pages || 1) > 1)
      throw new DomainError(
        "INVALID_IMAGE_TYPE",
        "Format aktual dan MIME harus JPEG atau PNG yang sama.",
        415,
      );
    const image = await decoder
      .rotate()
      .resize({
        width: 1600,
        height: 1600,
        fit: "contain",
        background: "#ffffff",
      })
      .jpeg({ quality: 85 })
      .toBuffer();
    return {
      key: key.toLowerCase(),
      mode,
      description,
      rawOcrText,
      quantity,
      consumedAt,
      image,
      original: file.buffer,
      fingerprintMetadata: {
        mode,
        description,
        rawOcrText,
        quantity: req.body.quantity ?? null,
        consumedAt: req.body.consumedAt ?? null,
      },
    };
  } catch (error) {
    if (error instanceof DomainError) throw error;
    throw new DomainError(
      "INVALID_IMAGE",
      "Gambar tidak dapat dibaca atau melebihi 20 megapixel.",
      415,
    );
  }
}
