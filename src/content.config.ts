import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const reference = z.object({
  title: z.string(),
  url: z.string().url(),
  section: z.string(),
  type: z.enum(['docs', 'book', 'paper', 'video', 'dataset', 'code']).optional(),
  lang: z.enum(['ar', 'en']).optional(),
  duration: z.string().optional(),
});

const lessons = defineCollection({
  // id = "<lang>/<slug>": the number prefix of the file name only orders files.
  loader: glob({
    base: './content/lessons',
    pattern: '{ar,en}/*.mdx',
    generateId: ({ entry }) => entry.replace(/\.mdx$/, '').replace(/\/\d\d-\d\d-/, '/'),
  }),
  schema: z
    .object({
      title: z.string(),
      titleEn: z.string().optional(),
      description: z.string(),
      station: z.number().int().min(0).max(10),
      order: z.number().int().min(1),
      level: z.enum(['core', 'recommended', 'optional']),
      status: z.enum(['draft', 'review', 'approved']),
      objectives: z.array(z.string()).min(1).max(4),
      prerequisites: z.array(z.string()).default([]),
      references: z.array(reference).min(1),
      datasets: z.array(z.enum(['D1', 'D2', 'D3', 'D4', 'D6'])).default([]),
      startingPoint: z
        .object({ dataset: z.string(), file: z.string(), applied: z.array(z.string()), script: z.string() })
        .optional(),
      interactive: z.array(z.string()).default([]),
      eeglabVersion: z.string(),
      updated: z.coerce.date(),
    })
    .strict(),
});

export const collections = { lessons };
