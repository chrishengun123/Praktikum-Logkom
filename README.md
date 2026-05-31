# UNI

## Tentang Program

Program ini dikembangkan untuk memenuhi Tugas Besar IF1221 Logika Komputasional. Program ini mensimulasikan permainan _UNI_ (sebuah _spin-off_ dari UNO) yang diimplementasikan dalam bahasa Prolog (Programming in Logic). Program ini menggunakan GNU Prolog (gprolog) sebagai compiler utamanya. Program ini juga memanfaatkan materi prolog yang sudah dipelajari dalam kelas seperti Rekursens, List, Cut, Fail, Loop, dan File Processing

### Fitur Utama

- **Start & End Game**: Memulai permainan dan berhenti sesi permainan UNI.
- **Up to 4 Players!**: Permainan dapat dilakukan dengan 2-4 player.
- **All sorts of Colors!**: Kartu-kartu uni dimulai dari angka 0-9 dan action cards seperti reverse, skip, draw 2, wild, wild draw 4, dan mimic.
- **Tangkap Player**: Dapat digunakan ketika player lupa memanggil uni.
- **Tantang Player**: Dapat digunakan ketika player memainkan wild draw 4, dan turn player selanjutnya memikirkan player tersebut memiliki draw lagi.
- **Helpful Guide**: Command seperti lihatKartu, lihatCommand, dan cekInfo dapat digunakan ketika tidak tahu apa yang dapat dilakukan.
- **Save/Load Data**: Permainan yang tidak selesai dapat disimpan dalam .TXT file yang kemudian dapat diload kembali ketika ingin dilanjutkan.

## Struktur Folder

```text
Praktikum IF1221 Logika Komputasional G07
├── Makefile            # Instruksi kompilasi otomatis
├── doc/
    ├── Milestone1_G07.pdf
    ├── Milestone2_G07.pdf
    └── Laporan_G07.pdf
├── src/
    ├── uni.pl
    ├── random_card.pl
    ├── file_read_write.pl
│   ├── lihat_kartu_dan_tantang.pl
│   └── pool.txt
└── README.md
```

## Persyaratan

Pastikan sistem Anda sudah terinstal:

- **gprolog** (GNU Prolog) - untuk kompilasi program prolog
- **make** - untuk automasi running

Untuk mengecek apakah sudah terinstal, jalankan:

```bash
gprolog --version
make --version
```

## How to Run

### Run Program

Untuk build dan menjalankan program:

```bash
make runi
```

## Kredit

Dikembangkan oleh **Kelompok G07** IF1221 Logika Komputasional Institut Teknologi Bandung Semester 2 Tahun 2025/2026

| No. | NIM                                     | Nama                                                             |
| --- | --------------------------------------- | ---------------------------------------------------------------- |
| 1.  | [13525061](13525061@std.stei.itb.ac.id) | [Rifqi Irfan Indrawan](https://github.com/TSZCodes)              |
| 2.  | [13525065](13525065@std.stei.itb.ac.id) | [Christopher Hendrik Gunawan](https://github.com/chrishengun123) |
| 3.  | [13525083](13525083@std.stei.itb.ac.id) | [Natanael Chris Fabian Santoso](https://github.com/nateuplord)   |
| 4.  | [13525149](13525149@std.stei.itb.ac.id) | [Ferdinand Valentino Darmawan](https://github.com/LinnaVal)      |
