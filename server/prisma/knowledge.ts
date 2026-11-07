// Original Indonesian paraphrases of reviewed FDA educational text; no food nutrient records.
// Source and reuse policy checked 2026-11-07. No FDA images/logos or third-party material copied.
export const knowledge = [
  {
    id: 'fda-serving-basis', title: 'Takaran saji dan jumlah konsumsi', tags: ['Kalori', 'Keseimbangan', 'Protein'],
    text: 'Angka pada label mengikuti takaran saji yang disebutkan. Jumlah sajian yang dimakan memengaruhi jumlah energi dan nutrisi yang dikonsumsi. Periksa takaran dan jumlah sajian; takaran pada label bukan rekomendasi jumlah yang harus dimakan.',
  },
  {
    id: 'fda-sugar-types', title: 'Gula total berbeda dari gula tambahan', tags: ['Gula', 'Keseimbangan'],
    text: 'Gula total dapat mencakup gula yang secara alami terdapat dalam bahan serta gula tambahan. Jangan menyimpulkan seluruh gula total sebagai gula tambahan bila label tidak menyebutkannya. Periksa jenis gula dan acuan per sajian sebelum membandingkan.',
  },
  {
    id: 'fda-nutrient-context', title: 'Membaca beberapa nutrisi bersama', tags: ['Natrium', 'Protein', 'Keseimbangan', 'Kalori'],
    text: 'Label membantu membandingkan energi dan berbagai nutrisi. FDA menyoroti lemak jenuh, natrium, dan gula tambahan sebagai nutrisi yang perlu diperhatikan jumlahnya. Satu nutrisi saja tidak menggambarkan seluruh pilihan makanan; bandingkan pada takaran setara dan lihat informasi yang tersedia.',
  },
].map(item => ({ ...item,
  sourceUrl: 'https://www.fda.gov/food/nutrition-facts-label/how-understand-and-use-nutrition-facts-label',
  sourceTitle: 'FDA: How to Understand and Use the Nutrition Facts Label',
  version: 'source-2024-03-05-review-2026-11', reviewed: true, reviewedAt: new Date('2026-11-07T00:00:00Z'),
  license: 'Original paraphrase; US federal FDA text, public domain. https://www.fda.gov/about-fda/about-website/website-policies',
}));
