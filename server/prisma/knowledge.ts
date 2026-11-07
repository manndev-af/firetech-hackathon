// Original Indonesian paraphrases of reviewed FDA educational text; no food nutrient records.
// Source and reuse policy checked 2026-11-07. No FDA images/logos or third-party material copied.
const fdaKnowledge = [
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

// User-supplied Kemenkes paraphrases approved for retrieval by repository owner on 2026-11-08.
// PDF URL supplied by owner; PDF claims and reuse terms have not been independently verified here.
export const kemenkesKnowledge = [
  {
    id: "kemenkes-permenkes-41-2014-empat-pilar-gizi-seimbang",
    title: "Empat Pilar dalam Pedoman Gizi Seimbang",
    text: "Pedoman Gizi Seimbang terdiri dari empat pilar yang saling berkaitan. Pilar pertama adalah mengonsumsi anekaragam pangan, karena tidak ada satu jenis makanan yang dapat menyediakan seluruh zat gizi yang dibutuhkan tubuh. Pilar kedua adalah membiasakan perilaku hidup bersih untuk mengurangi risiko infeksi yang dapat memengaruhi status gizi. Pilar ketiga adalah melakukan aktivitas fisik untuk membantu menyeimbangkan energi yang masuk dan keluar dari tubuh. Pilar keempat adalah memantau berat badan secara teratur. Keempat pilar ini menunjukkan bahwa gizi seimbang tidak hanya berkaitan dengan jenis makanan, tetapi juga kebiasaan hidup sehari-hari.",
    tags: ["Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-keanekaragaman-dan-proporsi-pangan",
    title: "Keanekaragaman dan Proporsi Makanan Sehari-hari",
    text: "Keanekaragaman pangan mencakup makanan pokok, lauk pauk, sayuran, buah-buahan, dan air. Variasi tidak hanya berarti memilih makanan dari kelompok yang berbeda, tetapi juga mengganti jenis makanan di dalam kelompok yang sama. Contohnya, sumber karbohidrat dapat berasal dari beras, jagung, singkong, ubi, talas, atau sagu. Namun, makanan yang beragam tetap perlu dikonsumsi dengan jumlah dan proporsi yang sesuai, cukup, tidak berlebihan, dan teratur. Pedoman ini juga menganjurkan lebih banyak konsumsi sayuran dan buah-buahan serta mengurangi makanan yang mengandung gula, garam, dan lemak secara berlebihan.",
    tags: ["Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-porsi-sayur-dan-buah",
    title: "Anjuran Konsumsi Sayur dan Buah Berdasarkan Kelompok Umur",
    text: "Pedoman ini menjelaskan bahwa sayuran dan buah-buahan merupakan sumber vitamin, mineral, dan serat pangan. Konsumsi keduanya dianjurkan sebanyak 300–400 gram per orang per hari untuk anak balita dan anak usia sekolah, serta 400–600 gram per orang per hari untuk remaja dan orang dewasa. Sekitar dua pertiga dari jumlah tersebut merupakan porsi sayuran. Sebagai gambaran, satu porsi sayuran golongan B atau C sekitar satu gelas sayuran setelah dimasak dan ditiriskan. Anjuran jumlah sayur dan buah ini merupakan pedoman berdasarkan kelompok umur, bukan angka kebutuhan personal yang berlaku sama untuk setiap orang.",
    tags: ["Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-protein-hewani-dan-nabati",
    title: "Variasi Sumber Protein Hewani dan Nabati",
    text: "Sumber protein dalam pedoman ini dibagi menjadi pangan hewani dan nabati. Protein hewani dapat berasal dari ikan, daging, unggas, telur, susu, dan hasil olahannya. Protein nabati dapat berasal dari kacang-kacangan serta produk seperti tahu dan tempe. Kedua kelompok sama-sama menyediakan protein, tetapi mempunyai karakteristik berbeda. Pangan hewani memiliki asam amino lebih lengkap dan zat gizi yang lebih mudah diserap, sedangkan pangan nabati umumnya memiliki proporsi lemak tidak jenuh lebih banyak. Pedoman menganjurkan konsumsi kedua kelompok secara bersama dengan pangan lainnya. Jumlah porsinya perlu disesuaikan dengan umur dan kondisi fisiologis, seperti kehamilan, menyusui, dan usia lanjut.",
    tags: ["Protein", "Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-takaran-porsi-dan-penukar-karbohidrat",
    title: "Takaran Porsi dan Pilihan Pengganti Makanan Sumber Karbohidrat",
    text: "Dokumen menyediakan daftar makanan sumber karbohidrat yang dapat digunakan sebagai penukar satu porsi nasi. Satu porsi nasi putih dalam contoh pedoman memiliki berat sekitar 100 gram atau setara tiga perempat gelas, dengan kandungan 175 Kalori, 4 gram protein, dan 40 gram karbohidrat. Beberapa pilihan penukarnya adalah jagung segar sebanyak tiga buah sedang dengan berat 125 gram, kentang dua buah sedang dengan berat 210 gram, dan singkong satu setengah potong dengan berat 120 gram. Daftar tersebut menggunakan ukuran rumah tangga dan berat dalam gram. Nilai ini merupakan padanan porsi dalam tabel, bukan komposisi nutrisi universal untuk semua cara pengolahan makanan.",
    tags: ["Kalori", "Protein", "Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-serat-dan-serealia-utuh",
    title: "Serat pada Serealia Utuh dan Pilihan Makanan Pokok",
    text: "Pedoman menjelaskan bahwa makanan pokok tidak hanya berasal dari beras, tetapi juga dapat berupa jagung, singkong, ubi, talas, garut, sorgum, jewawut, dan sagu. Serealia utuh seperti jagung, beras merah, beras hitam, serta biji-bijian yang tidak disosoh mengandung serat lebih tinggi. Serat tersebut berperan dalam melancarkan buang air besar dan membantu pengendalian kolesterol darah. Dokumen juga menjelaskan bahwa karbohidrat dari serealia utuh lebih lambat diubah menjadi gula darah dibandingkan sumber yang dijelaskan dalam pembahasan tersebut. Variasi makanan pokok dapat dilakukan dengan mengonsumsi lebih dari satu jenis sumber karbohidrat dalam sehari atau sekali makan.",
    tags: ["Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-batas-konsumsi-gula",
    title: "Batas Konsumsi Gula dan Cara Menguranginya",
    text: "Pedoman menyebutkan bahwa konsumsi gula lebih dari 50 gram atau sekitar empat sendok makan per orang per hari dapat meningkatkan risiko hipertensi, stroke, diabetes, dan serangan jantung dalam konteks pembahasan konsumsi gula, garam, dan lemak. Gula tidak hanya terdapat pada gula pasir, gula aren, dan gula jagung, tetapi juga dapat ditemukan pada makanan dan minuman lain seperti roti, kecap, buah manis, jus, dan minuman bersoda. Dokumen menganjurkan pembatasan makanan dan minuman manis, pengurangan gula tambahan dalam minuman dan masakan, serta pemilihan makanan penutup berupa buah yang kurang manis atau sayuran segar. Angka tersebut merupakan batas konsumsi yang disebutkan dalam dokumen, bukan target konsumsi gula personal.",
    tags: ["Gula"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-natrium-dan-garam",
    title: "Perbedaan Garam dan Natrium serta Pilihan Makanan Rendah Natrium",
    text: "Pedoman menjelaskan bahwa rasa asin pada makanan berkaitan dengan kandungan garam atau natrium klorida (NaCl), sedangkan natrium merupakan kandungan zat yang dicantumkan dalam daftar makanan tinggi natrium. Konsumsi natrium berlebihan dapat meningkatkan tekanan darah. Dokumen menyebutkan bahwa konsumsi natrium lebih dari 2.000 mg atau sekitar satu sendok teh per orang per hari dapat meningkatkan risiko penyakit tertentu. Contoh bahan penyedap tinggi natrium meliputi garam meja, acar bawang, MSG, kecap, dan pelunak daging. Pilihan yang dianjurkan antara lain membaca informasi nilai gizi pada pangan kemasan, memilih produk rendah natrium, mengurangi bumbu instan bergaram, dan menggunakan tomat, bawang, cabai, atau jahe untuk menambah rasa.",
    tags: ["Natrium"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-lemak-dan-minyak",
    title: "Fungsi Lemak, Anjuran Konsumsi, dan Variasi Sumber Lemak",
    text: "Lemak dalam makanan berfungsi sebagai sumber energi, membantu penyerapan vitamin A, D, E, dan K, serta menambah cita rasa makanan. Pedoman menganjurkan konsumsi lemak dan minyak dalam hidangan sehari-hari tidak lebih dari 25 persen kebutuhan energi. Dokumen membedakan sumber lemak berdasarkan kandungan asam lemaknya menjadi lemak tak jenuh dan lemak jenuh. Sumber lemak tak jenuh umumnya berasal dari pangan nabati, kecuali minyak kelapa, sedangkan lemak jenuh umumnya berasal dari pangan hewani. Contoh bahan yang tercantum dalam tabel penukar meliputi minyak zaitun, minyak jagung, alpukat, mentega, santan, dan minyak sawit. Khusus anak usia 6–24 bulan, dokumen menyatakan konsumsi lemak tidak perlu dibatasi.",
    tags: ["Kalori", "Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-membaca-label-pangan",
    title: "Membaca Label dan Informasi Nilai Gizi pada Kemasan",
    text: "Label pangan merupakan keterangan pada kemasan yang memuat informasi mengenai isi, jenis, komposisi zat gizi, tanggal kedaluwarsa, dan informasi penting lainnya. Pedoman menganjurkan konsumen membaca label sebelum membeli atau mengonsumsi makanan kemasan, terutama informasi kandungan zat gizi dan tanggal kedaluwarsa. Informasi tersebut membantu konsumen mengetahui bahan yang terkandung dalam produk serta memperkirakan risiko bagi orang yang mempunyai kondisi kesehatan tertentu. Dalam memilih makanan, dokumen juga menganjurkan memanfaatkan informasi label untuk menemukan produk yang kurang manis atau rendah kalori serta membaca informasi nilai gizi untuk memilih pangan rendah natrium. Dokumen tidak memberikan metode perhitungan persentase kebutuhan harian berdasarkan label.",
    tags: ["Gula", "Natrium", "Kalori"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  },
  {
    id: "kemenkes-permenkes-41-2014-porsi-menurut-umur",
    title: "Perbedaan Porsi Makanan Berdasarkan Umur dan Jenis Kelamin",
    text: "Pedoman menyediakan tabel anjuran jumlah porsi makanan berdasarkan kelompok umur, jenis kelamin, serta kecukupan energi. Kelompok yang dicantumkan meliputi ibu hamil dan menyusui, anak usia 1–3 tahun, 4–6 tahun, 7–9 tahun, anak usia sekolah 10–12 tahun, remaja 13–18 tahun, dewasa 19–29 tahun, 30–49 tahun, 50–64 tahun, dan usia di atas 65 tahun. Jumlah porsi makanan pokok, sayuran, buah, tempe, daging atau ikan, susu, minyak, dan gula tidak selalu sama antarkelompok. Karena itu, tabel tersebut tidak boleh diterapkan sebagai kebutuhan pasti bagi semua pengguna. Angka porsi harus dibaca bersama kelompok sasaran dan kecukupan energi yang tercantum pada tabel.",
    tags: ["Kalori", "Protein", "Keseimbangan"],
    sourceUrl: "https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf",
    sourceTitle: "Peraturan Menteri Kesehatan Republik Indonesia Nomor 41 Tahun 2014 tentang Pedoman Gizi Seimbang",
    version: "source-2014-owner-review-2026-11",
    reviewed: true,
    reviewedAt: new Date("2026-11-08T00:00:00+07:00"),
    license: "Ketentuan penggunaan belum diverifikasi"
  }
];

export const knowledge = [...fdaKnowledge, ...kemenkesKnowledge];
