-- ============================================================
-- DATABASE SCHEMA - PT. WIRATAMA MITRA ABADI WAREHOUSE
-- Untuk implementasi dengan PostgreSQL / MySQL
-- ============================================================

-- TABEL MASTER BARANG
CREATE TABLE barang (
  id            SERIAL PRIMARY KEY,
  nomor         VARCHAR(50),
  rak           VARCHAR(50),
  brand         VARCHAR(100),
  manufacture   VARCHAR(100),
  kode          VARCHAR(100) UNIQUE NOT NULL,
  model         VARCHAR(100),
  type          VARCHAR(100),
  display       VARCHAR(100),
  installation  VARCHAR(100),
  power         VARCHAR(50),
  acc           VARCHAR(50),
  pressure      VARCHAR(50),
  body          VARCHAR(100),
  electrode     VARCHAR(100),
  liner         VARCHAR(100),
  flange_type   VARCHAR(100),
  kondisi       VARCHAR(50),
  keterangan    TEXT,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABEL BARANG MASUK
CREATE TABLE barang_masuk (
  id            SERIAL PRIMARY KEY,
  nomor         VARCHAR(50),
  rak           VARCHAR(50),
  brand         VARCHAR(100),
  manufacture   VARCHAR(100),
  kode          VARCHAR(100) REFERENCES barang(kode),
  model         VARCHAR(100),
  type          VARCHAR(100),
  display       VARCHAR(100),
  installation  VARCHAR(100),
  power         VARCHAR(50),
  acc           VARCHAR(50),
  pressure      VARCHAR(50),
  body          VARCHAR(100),
  electrode     VARCHAR(100),
  liner         VARCHAR(100),
  flange_type   VARCHAR(100),
  qty           INTEGER NOT NULL CHECK (qty > 0),
  kondisi       VARCHAR(50),
  keterangan    TEXT,
  tanggal_masuk DATE NOT NULL,
  admin_id      INTEGER,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABEL BARANG KELUAR
CREATE TABLE barang_keluar (
  id             SERIAL PRIMARY KEY,
  nomor          VARCHAR(50),
  rak            VARCHAR(50),
  brand          VARCHAR(100),
  manufacture    VARCHAR(100),
  kode           VARCHAR(100) REFERENCES barang(kode),
  model          VARCHAR(100),
  type           VARCHAR(100),
  display        VARCHAR(100),
  installation   VARCHAR(100),
  power          VARCHAR(50),
  acc            VARCHAR(50),
  pressure       VARCHAR(50),
  body           VARCHAR(100),
  electrode      VARCHAR(100),
  liner          VARCHAR(100),
  flange_type    VARCHAR(100),
  qty            INTEGER NOT NULL CHECK (qty > 0),
  kondisi        VARCHAR(50),
  keterangan     TEXT,
  tanggal_keluar DATE NOT NULL,
  admin_id       INTEGER,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABEL STOK BARANG
CREATE TABLE stok_barang (
  kode          VARCHAR(100) PRIMARY KEY REFERENCES barang(kode),
  nomor         VARCHAR(50),
  rak           VARCHAR(50),
  brand         VARCHAR(100),
  manufacture   VARCHAR(100),
  model         VARCHAR(100),
  type          VARCHAR(100),
  display       VARCHAR(100),
  installation  VARCHAR(100),
  power         VARCHAR(50),
  acc           VARCHAR(50),
  pressure      VARCHAR(50),
  body          VARCHAR(100),
  electrode     VARCHAR(100),
  liner         VARCHAR(100),
  flange_type   VARCHAR(100),
  kondisi       VARCHAR(50),
  keterangan    TEXT,
  total_masuk   INTEGER DEFAULT 0,
  total_keluar  INTEGER DEFAULT 0,
  stok_akhir    INTEGER DEFAULT 0,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- INDEX untuk performa
CREATE INDEX idx_barang_masuk_kode ON barang_masuk(kode);
CREATE INDEX idx_barang_keluar_kode ON barang_keluar(kode);
CREATE INDEX idx_barang_masuk_tanggal ON barang_masuk(tanggal_masuk);
CREATE INDEX idx_barang_keluar_tanggal ON barang_keluar(tanggal_keluar);

-- TRIGGER: Update stok otomatis saat INSERT barang_masuk
CREATE OR REPLACE FUNCTION update_stok_masuk()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO stok_barang (kode, total_masuk, stok_akhir)
  VALUES (NEW.kode, NEW.qty, NEW.qty)
  ON CONFLICT (kode) DO UPDATE
  SET total_masuk = stok_barang.total_masuk + NEW.qty,
      stok_akhir  = stok_barang.stok_akhir  + NEW.qty,
      updated_at  = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_masuk_insert
AFTER INSERT ON barang_masuk
FOR EACH ROW EXECUTE FUNCTION update_stok_masuk();

-- TRIGGER: Update stok otomatis saat INSERT barang_keluar
CREATE OR REPLACE FUNCTION update_stok_keluar()
RETURNS TRIGGER AS $$
DECLARE v_stok INTEGER;
BEGIN
  SELECT stok_akhir INTO v_stok FROM stok_barang WHERE kode = NEW.kode;
  IF v_stok IS NULL OR v_stok < NEW.qty THEN
    RAISE EXCEPTION 'Stok tidak mencukupi! Stok tersedia: %', COALESCE(v_stok, 0);
  END IF;
  UPDATE stok_barang
  SET total_keluar = total_keluar + NEW.qty,
      stok_akhir   = stok_akhir   - NEW.qty,
      updated_at   = CURRENT_TIMESTAMP
  WHERE kode = NEW.kode;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_keluar_insert
AFTER INSERT ON barang_keluar
FOR EACH ROW EXECUTE FUNCTION update_stok_keluar();
